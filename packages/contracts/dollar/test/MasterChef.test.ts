import { ethers } from "hardhat";
import { describe, it } from "mocha";
import { BigNumber, Signer } from "ethers";
import { expect } from "./setup";
import { bondingSetup } from "./BondingSetup";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { MasterChef } from "../artifacts/types/MasterChef";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { mineNBlock } from "./utils/hardhatNode";
import { swap3CRVtoUAD } from "./utils/swap";
import { ERC20 } from "../artifacts/types/ERC20";
import { calculateUGOVMultiplier, isAmountEquivalent } from "./utils/calc";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { Bonding } from "../artifacts/types/Bonding";
import { BondingShare } from "../artifacts/types/BondingShare";

describe("MasterChef", () => {
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
  let masterChef: MasterChef;

  let secondAccount: Signer;
  let curveWhale: Signer;
  let treasury: Signer;
  let secondAddress: string;
  let metaPool: IMetaPool;
  let twapOracle: TWAPOracle;
  let uAD: UbiquityAlgorithmicDollar;
  let crvToken: ERC20;
  let uGOV: UbiquityGovernance;
  let uGOVRewardForHundredBlock: BigNumber;
  let bonding: Bonding;
  let bondingShare: BondingShare;

  before(async () => {
    ({ masterChef, bonding, bondingShare, uGOV, curveWhale, treasury, crvToken, secondAccount, metaPool, twapOracle, uAD } = await bondingSetup());
    secondAddress = await secondAccount.getAddress();
    // for testing purposes set the week equal to one block
    await bonding.setBlockCountInAWeek(1);
  });

  describe("TwapPrice", () => {
    it("TwapPrice should be 1", async () => {
      const twapPrice = await twapOracle.consult(uAD.address);
      expect(twapPrice).to.be.equal(one);
    });
  });

  describe("updateUGOVMultiplier", () => {
    it("should update UGOVMultiplier, and get multiplied by 1.05 at price 1", async () => {
      const m0 = await masterChef.uGOVmultiplier();
      expect(m0).to.equal(ethers.utils.parseEther("1")); // m0 = m1 * 1.05
      // push uAD price down
      await swap3CRVtoUAD(metaPool, crvToken, ethers.utils.parseEther("1000"), curveWhale);
      await twapOracle.update();
      await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
      await twapOracle.update();

      const twapPrice = await twapOracle.consult(uAD.address);
      expect(twapPrice).to.be.gt(one);
      //  multiplier * ( 1.05 / (1 + abs( 1 - price ) ) )
      const calcMultiplier = calculateUGOVMultiplier(m0.toString(), twapPrice.toString());

      // need to do a deposit to trigger the uGOV Multiplier calculation
      await metaPool.connect(secondAccount).approve(bonding.address, one);
      await bonding.connect(secondAccount).deposit(one, 1);
      const m1 = await masterChef.uGOVmultiplier();

      expect(m1).to.equal(calcMultiplier);
      // assert that if the price doesn't change neither is the multiplier
      const user = await masterChef.connect(secondAccount).userInfo(secondAddress);
      const tokenIds = await bondingShare.holderTokens(secondAddress);

      await bonding.connect(secondAccount).withdraw(user.amount, tokenIds[0]);

      const m2 = await masterChef.uGOVmultiplier();
      expect(m1).to.equal(m2); // m2 = m1 * 1.05
    });
  });

  describe("deposit", () => {
    it("should be able to deposit", async () => {
      const amount = one.mul(100);
      await metaPool.connect(secondAccount).approve(bonding.address, amount);
      await expect(bonding.connect(secondAccount).deposit(amount, 1)).to.emit(metaPool, "Transfer").withArgs(secondAddress, bonding.address, amount);

      const user = await masterChef.connect(secondAccount).userInfo(secondAddress);
      // user amount is equal to the amount of user's bonding share
      const tokensID = await bondingShare.holderTokens(secondAddress);
      const secondAccountSharebalance = await bondingShare.balanceOf(secondAddress, tokensID[0]);
      expect(user.amount).to.equal(secondAccountSharebalance);
      // do not have pending rewards just after depositing
      const pendingUGOV = await masterChef.pendingUGOV(secondAddress);
      expect(pendingUGOV).to.equal(0);

      const pool = await masterChef.pool();
      expect(user.rewardDebt).to.equal(user.amount.mul(pool.accuGOVPerShare).div(BigNumber.from(10).pow(12)));
    });

    it("should calculate pendingUGOV after 100 blocks", async () => {
      await mineNBlock(100);
      const pendingUGOV = await masterChef.pendingUGOV(secondAddress);
      const uGOVmultiplier = await masterChef.uGOVmultiplier();
      const uGOVPerBlock = await masterChef.uGOVPerBlock();
      const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
      const pool = await masterChef.pool();
      const fromBlock = pool.lastRewardBlock;
      const numberOfBlock = lastBlock.number - fromBlock.toNumber();
      expect(numberOfBlock).to.equal(100);

      // uGOVReward = (( (_to - _from) * uGOVmultiplier ) * uGOVPerBlock) / 1e18
      uGOVRewardForHundredBlock = BigNumber.from(numberOfBlock).mul(uGOVmultiplier).mul(uGOVPerBlock).div(one);

      const totalLPSupply = await bondingShare.totalSupply();
      // (uGOVReward * 1e12) / lpSupply)
      // here as the amount is the amount of bonding shares
      // we should divide by the total supply to get
      // the uGOV per share
      const accuGOVPerShare = uGOVRewardForHundredBlock.mul(BigNumber.from(10).pow(12)).div(totalLPSupply);

      const user = await masterChef.connect(secondAccount).userInfo(secondAddress);

      const pendingCalculated = user.amount.mul(accuGOVPerShare).div(BigNumber.from(10).pow(12));

      const isPrecise = isAmountEquivalent(pendingUGOV.toString(), pendingCalculated.toString(), "0.0000000000000000001");
      expect(isPrecise).to.be.true;
    });
  });

  describe("withdraw", () => {
    it("should be able to withdraw", async () => {
      // get reward
      const lastBlockB = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
      const poolB = await masterChef.pool();
      const fromBlockB = poolB.lastRewardBlock;
      const numberOfBlockB = lastBlockB.number - fromBlockB.toNumber();
      const auGOVmultiplier = await masterChef.uGOVmultiplier();
      const uGOVPerBlockB = await masterChef.uGOVPerBlock();
      const calculatedUGOVRewardToBeMinted = BigNumber.from(numberOfBlockB + 1)
        .mul(auGOVmultiplier)
        .mul(uGOVPerBlockB)
        .div(one);

      const uGovBalanceBefore = await uGOV.balanceOf(secondAddress);

      await expect(masterChef.connect(secondAccount).getRewards())
        .to.emit(uGOV, "Transfer")
        .withArgs(ethers.constants.AddressZero, masterChef.address, calculatedUGOVRewardToBeMinted) // minting uGOV
        .and.to.emit(uGOV, "Transfer")
        .withArgs(ethers.constants.AddressZero, await treasury.getAddress(), calculatedUGOVRewardToBeMinted.div(5)); // minting for treasury
      const uGovBalanceAfter = await uGOV.balanceOf(secondAddress);

      // as there is only one LP provider he gets pretty much all the rewards
      const isPrecise = isAmountEquivalent(uGovBalanceAfter.toString(), uGovBalanceBefore.add(calculatedUGOVRewardToBeMinted).toString(), "0.000000000001");
      expect(isPrecise).to.be.true;

      // do not have pending rewards anymore just after withdrawing rewards
      const pendingUGOV = await masterChef.pendingUGOV(secondAddress);
      expect(pendingUGOV).to.equal(0);

      // push the price further so that the reward should be less than previously
      // push uAD price down

      await swap3CRVtoUAD(metaPool, crvToken, ethers.utils.parseEther("10000"), curveWhale);
      await twapOracle.update();
      await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
      await twapOracle.update();
      const twapPrice3 = await twapOracle.consult(uAD.address);

      expect(twapPrice3).to.be.gt(one);
      // should withdraw rewards to trigger the uGOVmultiplier
      await masterChef.connect(secondAccount).getRewards();
      await mineNBlock(100);

      const uGOVmultiplier = await masterChef.uGOVmultiplier();
      const uGOVPerBlock = await masterChef.uGOVPerBlock();
      const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
      const pool = await masterChef.pool();
      const fromBlock = pool.lastRewardBlock;
      const numberOfBlock = lastBlock.number - fromBlock.toNumber();
      expect(numberOfBlock).to.equal(100);

      // uGOVReward = (( (_to - _from) * uGOVmultiplier ) * uGOVPerBlock) / 1e18
      const NewuGOVRewardForHundredBlock = BigNumber.from(numberOfBlock).mul(uGOVmultiplier).mul(uGOVPerBlock).div(one);

      expect(NewuGOVRewardForHundredBlock).to.be.lt(uGOVRewardForHundredBlock.div(BigNumber.from(2)));

      // calculating uGOV Rewards
      const totalLPSupply = await bondingShare.totalSupply();
      const user = await masterChef.connect(secondAccount).userInfo(secondAddress);
      const multiplier = BigNumber.from(101).mul(uGOVmultiplier);
      const uGOVReward = multiplier.mul(uGOVPerBlock).div(one);

      const pendingCalculated = multiplier.mul(uGOVPerBlock).div(one).mul(user.amount).div(totalLPSupply);

      // there is a loss of precision
      const lostPrecision = pendingCalculated.mod(BigNumber.from(1e8));

      // when withdrawing we also get our UGOV Rewards
      const tokenIds = await bondingShare.holderTokens(secondAddress);
      const baluGOVBefore = await uGOV.balanceOf(secondAddress);
      await expect(bonding.connect(secondAccount).withdraw(one.mul(100), tokenIds[0]))
        .to.emit(uGOV, "Transfer")
        // ugov minting
        .withArgs(ethers.constants.AddressZero, masterChef.address, uGOVReward);
      const baluGovAfter = await uGOV.balanceOf(secondAddress);

      const isRewardPrecise = isAmountEquivalent(baluGovAfter.sub(baluGOVBefore).toString(), pendingCalculated.sub(lostPrecision).toString(), "0.0000000001");

      expect(isRewardPrecise).to.be.true;
    });

    it("should retrieve pendingUGOV", async () => {
      expect(await masterChef.pendingUGOV(secondAddress)).to.be.equal(0);
    });
  });
});
