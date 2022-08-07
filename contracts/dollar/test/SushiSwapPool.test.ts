import { Signer, BigNumber, ContractFactory } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { expect } from "chai";

import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";
import { ISushiMasterChef } from "../artifacts/types/ISushiMasterChef";
import { IUniswapV2Factory } from "../artifacts/types/IUniswapV2Factory";
import { IUniswapV2Pair } from "../artifacts/types/IUniswapV2Pair";
import { IUniswapV2Router02 } from "../artifacts/types/IUniswapV2Router02";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { mineNBlock, resetFork } from "./utils/hardhatNode";

/*
      SUSHISWAP Glossary
    SushiSwap is a Uniswap v2 fork with the execption of the setFeeTo()
    that was called in the deployment setting 0.05% of the fee to the SushiMaker
    * SushiMaker will receive LP tokens from people trading on SushiSwap.
      Burn the LP tokens for the provided token pair and swap tokens for sushi
      finally send the sushi to the bar
    * SushiBar cpeople can enter with SUSHI, receive xSUSHI and later leave
      with even more SUSHI.
    * SushiRoll contract a migrator is provided, so people can easily move liquidity
      from Uniswap to SushiSwap.
    * SushiRoll contract a migrator is provided, so people can easily move liquidity
      from Uniswap to SushiSwap.
    * MasterChef enables the minting of new SUSHI token. It's the only way to create SUSHI
      This is possible by staking LP tokens inside the MasterChef. The higher the
      allocation points of a liquidity pool, the more SUSHI one receives for staking its LP tokens.
*/

const sushiToken = "0x6B3595068778DD592e39A122f4f5a5cF09C90fE2"; // sushi token
const USDTToken = "0xdAC17F958D2ee523a2206206994597C13D831ec7"; // USDT
const factoryAdr = "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac"; // SushiV2Factory mainnet
const routerAdr = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F"; // SushiV2Router02
const masterChefAdr = "0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd"; // MasterChef
const firstPair = "0x680A025Da7b1be2c204D7745e809919bCE074026"; // SushiSwap SUSHI/USDT LP (SLP)
const reserveA = "1518287028779922369700";
const reserveB = "15598625844";
const nbPairs = 1290;

describe("SushiSwapPool", () => {
  let admin: Signer;
  let secondAccount: Signer;
  let manager: UbiquityAlgorithmicDollarManager;
  let sushiUGOVPool: SushiSwapPool;
  let poolContract: IUniswapV2Pair;
  let sushiFactory: ContractFactory;
  let router: IUniswapV2Router02;
  let factory: IUniswapV2Factory;
  let sushiUSDTPair: IUniswapV2Pair;
  let uGOVPair: string;
  let uAD: UbiquityAlgorithmicDollar;
  let uGOV: UbiquityGovernance;
  let sushiMultiSig: string;
  beforeEach(async () => {
    await resetFork(12592661);
    ({ sushiMultiSig } = await getNamedAccounts());

    [admin, secondAccount] = await ethers.getSigners();
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;
    router = (await ethers.getContractAt("IUniswapV2Router02", routerAdr)) as IUniswapV2Router02;
    factory = (await ethers.getContractAt("IUniswapV2Factory", factoryAdr)) as IUniswapV2Factory;
    sushiUSDTPair = (await ethers.getContractAt("IUniswapV2Pair", firstPair)) as IUniswapV2Pair;

    const UAD = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await UAD.deploy(manager.address)) as UbiquityAlgorithmicDollar;
    await manager.setDollarTokenAddress(uAD.address);

    const UGOV = await ethers.getContractFactory("UbiquityGovernance");
    uGOV = (await UGOV.deploy(manager.address)) as UbiquityGovernance;
    await manager.setGovernanceTokenAddress(uGOV.address);
    sushiFactory = await ethers.getContractFactory("SushiSwapPool");
    sushiUGOVPool = (await sushiFactory.deploy(manager.address)) as SushiSwapPool;

    const mintings = [await secondAccount.getAddress()].map(
      async (signer): Promise<void> => {
        await uAD.mint(signer, ethers.utils.parseEther("10000"));
        await uGOV.mint(signer, ethers.utils.parseEther("1000"));
      }
    );
    await Promise.all(mintings);
    uGOVPair = await sushiUGOVPool.pair();
    poolContract = (await ethers.getContractAt("IUniswapV2Pair", uGOVPair)) as IUniswapV2Pair;
  });

  describe("SushiSwap Factory", () => {
    it(`should get ${nbPairs} pairs`, async () => {
      const allPairsLength: BigNumber = await factory.allPairsLength();

      expect(allPairsLength).to.be.equal(nbPairs);
    });
    it("should get first pair 0xB4e...", async () => {
      const pair = await factory.allPairs(0);
      expect(pair).to.be.equal(firstPair);
    });
  });

  describe("SushiSwap first Pair", () => {
    it("should get factory address from first pair", async () => {
      const pairFactoryAddress = await sushiUSDTPair.factory();
      expect(pairFactoryAddress).to.be.equal(factory.address);
    });
    it("should get tokens, reserves of first pair", async () => {
      const token0 = await sushiUSDTPair.token0();
      const token1 = await sushiUSDTPair.token1();
      const [reserve0, reserve1] = await sushiUSDTPair.getReserves();

      expect(token0).to.be.equal(sushiToken);
      expect(token1).to.be.equal(USDTToken);
      expect(reserve0).to.be.equal(reserveA);
      expect(reserve1).to.be.equal(reserveB);
    });
  });

  describe("SushiSwap", () => {
    it("should create pool", async () => {
      const token0 = await poolContract.token0();
      const token1 = await poolContract.token1();
      const [reserve0, reserve1] = await poolContract.getReserves();

      if (token0 === uAD.address) {
        expect(token0).to.be.equal(uAD.address);
        expect(token1).to.be.equal(uGOV.address);
      } else {
        expect(token0).to.be.equal(uGOV.address);
        expect(token1).to.be.equal(uAD.address);
      }
      expect(reserve0).to.be.equal("0");
      expect(reserve1).to.be.equal("0");
    });

    it("should provide liquidity to pool", async () => {
      let [reserve0, reserve1] = await poolContract.getReserves();
      expect(reserve0).to.equal(0);
      expect(reserve1).to.equal(0);

      // If the liquidity is to be added to an ERC-20/ERC-20 pair, use addLiquidity.
      const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
      // must allow to transfer token
      await uAD.connect(secondAccount).approve(routerAdr, ethers.utils.parseEther("10000"));
      await uGOV.connect(secondAccount).approve(routerAdr, ethers.utils.parseEther("1000"));
      const totSupplyBefore = await poolContract.totalSupply();
      expect(totSupplyBefore).to.equal(0);
      await expect(
        router
          .connect(secondAccount)
          .addLiquidity(
            uAD.address,
            uGOV.address,
            ethers.utils.parseEther("10000"),
            ethers.utils.parseEther("1000"),
            ethers.utils.parseEther("9900"),
            ethers.utils.parseEther("990"),
            await secondAccount.getAddress(),
            blockBefore.timestamp + 100
          )
      )
        .to.emit(poolContract, "Transfer") //  minting of uad;
        .withArgs(ethers.constants.AddressZero, ethers.constants.AddressZero, 1000);

      [reserve0, reserve1] = await poolContract.getReserves();
      if ((await poolContract.token0()) === uAD.address) {
        expect(reserve0).to.equal(ethers.utils.parseEther("10000"));
        expect(reserve1).to.equal(ethers.utils.parseEther("1000"));
      } else {
        expect(reserve1).to.equal(ethers.utils.parseEther("10000"));
        expect(reserve0).to.equal(ethers.utils.parseEther("1000"));
      }

      const balance = await poolContract.balanceOf(await secondAccount.getAddress());

      const totSupply = await poolContract.totalSupply();
      // a small amount is burned for the first deposit
      // see https://uniswap.org/whitepaper.pdf page 9 second paragraph
      expect(balance).to.equal(totSupply.sub(BigNumber.from(1000)));
    });

    it("should not create pool if it exist ", async () => {
      const allPairsLength = await factory.allPairsLength();
      const newSushi = (await sushiFactory.deploy(manager.address)) as SushiSwapPool;
      const allPairsLengthAfterDeploy = await factory.allPairsLength();
      expect(allPairsLength).to.equal(allPairsLengthAfterDeploy);
      expect(await newSushi.pair()).to.equal(await sushiUGOVPool.pair());
    });

    it("should add pool and earn sushi", async () => {
      const secondAccAdr = await secondAccount.getAddress();
      // must allow to transfer token
      await uAD.connect(secondAccount).approve(routerAdr, ethers.utils.parseEther("10000"));
      await uGOV.connect(secondAccount).approve(routerAdr, ethers.utils.parseEther("1000"));
      // If the liquidity is to be added to an ERC-20/ERC-20 pair, use addLiquidity.
      const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
      await router
        .connect(secondAccount)
        .addLiquidity(
          uAD.address,
          uGOV.address,
          ethers.utils.parseEther("10000"),
          ethers.utils.parseEther("1000"),
          ethers.utils.parseEther("9900"),
          ethers.utils.parseEther("990"),
          secondAccAdr,
          blockBefore.timestamp + 100
        );
      const balanceBefore = await poolContract.balanceOf(secondAccAdr);
      const masterChef = (await ethers.getContractAt("ISushiMasterChef", masterChefAdr)) as ISushiMasterChef;
      const poolLengthBefore = await masterChef.poolLength();
      const owner = await masterChef.owner();
      expect(owner).to.equal("0x9a8541Ddf3a932a9A922B607e9CF7301f1d47bD1");
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [sushiMultiSig],
      });
      await secondAccount.sendTransaction({
        to: sushiMultiSig,
        value: ethers.utils.parseEther("2.0"),
      });

      const totAllocPoint = await masterChef.totalAllocPoint();
      const sushiChef = ethers.provider.getSigner(sushiMultiSig);
      // insert uGOV-UAD as onsen pair we will get half of all the sushi reward
      const blockNum = await ethers.provider.getBlockNumber();
      await masterChef.connect(sushiChef).add(totAllocPoint, uGOVPair, true);
      const totAllocPointAfterAdd = await masterChef.totalAllocPoint();
      expect(totAllocPointAfterAdd).to.equal(totAllocPoint.mul(BigNumber.from(2)));
      const poolLengthAfter = await masterChef.poolLength();
      // ugov pid should be the last index
      const uGOVpid = poolLengthAfter.sub(BigNumber.from(1));
      const pooluGOV = await masterChef.poolInfo(uGOVpid);

      expect(poolLengthAfter).to.equal(poolLengthBefore.add(BigNumber.from(1)));
      expect(pooluGOV.lpToken).to.equal(uGOVPair);
      expect(pooluGOV.allocPoint).to.equal(totAllocPoint);
      expect(pooluGOV.lastRewardBlock).to.equal(blockNum + 1);
      expect(pooluGOV.accSushiPerShare).to.equal(0);

      // deposit lp tokens
      // must allow to transfer LP token
      await poolContract.connect(secondAccount).approve(masterChefAdr, balanceBefore);

      // deposit all LP token
      await masterChef.connect(secondAccount).deposit(uGOVpid, balanceBefore);
      const uInfo = await masterChef.userInfo(uGOVpid, secondAccAdr);
      expect(uInfo.amount).to.equal(balanceBefore);
      expect(uInfo.rewardDebt).to.equal(0);

      const balanceAfter = await poolContract.balanceOf(secondAccAdr);
      expect(balanceAfter).to.equal(0);
      // pending sushi reward
      let pendingReward = await masterChef.pendingSushi(uGOVpid, secondAccAdr);
      expect(pendingReward).to.equal(0);

      // after one block we should be able to retrieve sushi
      await mineNBlock(1);
      pendingReward = await masterChef.pendingSushi(uGOVpid, secondAccAdr);
      const sushiPerBlock = await masterChef.sushiPerBlock();
      // we have half of the total allocation point so we are entitled to half the sushi per block

      // take into consideration precision
      expect(pendingReward).to.be.lte(sushiPerBlock);
      expect(pendingReward).to.be.gte(sushiPerBlock.mul(9999).div(20000));
    });
  });
});
