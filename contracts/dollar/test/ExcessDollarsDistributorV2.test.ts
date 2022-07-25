import { BigNumber, Signer } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { ERC20 } from "../artifacts/types/ERC20";
import { bondingSetupV2 } from "./BondingSetupV2";
import { IUniswapV2Router02 } from "../artifacts/types/IUniswapV2Router02";
import { IUniswapV2Pair } from "../artifacts/types/IUniswapV2Pair";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { ExcessDollarsDistributor } from "../artifacts/types/ExcessDollarsDistributor";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { isAmountEquivalent } from "./utils/calc";

describe("ExcessDollarsDistributorV2", () => {
  let metaPool: IMetaPool;
  let manager: UbiquityAlgorithmicDollarManager;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let treasury: Signer;
  let bondingV2: BondingV2;
  let uAD: UbiquityAlgorithmicDollar;
  let crvToken: ERC20;
  let uGOV: UbiquityGovernance;
  let sushiUGOVPool: SushiSwapPool;
  let treasuryAdr: string;
  let excessDollarsDistributor: ExcessDollarsDistributor;
  const routerAdr = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F"; // SushiV2Router02
  let router: IUniswapV2Router02;

  beforeEach(async () => {
    ({
      secondAccount,
      thirdAccount,
      uGOV,
      manager,
      bondingV2,
      treasury,
      uAD,
      metaPool,
      crvToken,
      sushiUGOVPool,
      excessDollarsDistributor,
    } = await bondingSetupV2());
    treasuryAdr = await treasury.getAddress();
    router = (await ethers.getContractAt("IUniswapV2Router02", routerAdr)) as IUniswapV2Router02;
    // just mint som uAD
    // mint 10000 uAD each for admin, manager and secondAccount
    const mintings = [await secondAccount.getAddress(), await thirdAccount.getAddress(), manager.address].map(
      async (signer): Promise<void> => {
        await uAD.mint(signer, ethers.utils.parseEther("10000"));
      }
    );
    await Promise.all(mintings);

    await uGOV.mint(await thirdAccount.getAddress(), ethers.utils.parseEther("1000"));
  });
  it("distributeDollars should do nothing if total uAD is 0", async () => {
    await excessDollarsDistributor.distributeDollars();
    const treasuryBalance = await uAD.balanceOf(treasuryAdr);
    expect(treasuryBalance).to.equal(0);
  });

  it("distributeDollars should work", async () => {
    // simulate distribution of uAD to ExcessDollarDistributor
    const amount = ethers.utils.parseEther("101");
    const tenPercent = amount.mul(10).div(100);
    const fiftyPercent = amount.div(2);
    await uAD.connect(secondAccount).transfer(excessDollarsDistributor.address, amount);
    let excessDollarBalance = await uAD.balanceOf(excessDollarsDistributor.address);
    expect(excessDollarBalance).to.equal(amount);
    // amount of LP token to send to bonding contract
    const dyuADto3CRV = await metaPool["get_dy(int128,int128,uint256)"](0, 1, amount.sub(fiftyPercent).sub(tenPercent));
    // calculate the  amount of LP tokens minted based on the 3CRV deposit
    const dyuAD2LP = await metaPool["calc_token_amount(uint256[2],bool)"]([0, dyuADto3CRV], true);

    const LPInBondingBeforeDistribute = await metaPool.balanceOf(bondingV2.address);
    expect(LPInBondingBeforeDistribute).to.equal("403499587827859697762");
    // provide liquidity to the pair uAD-UGOV so that 1 uGOV = 10 uAD
    const secondAccAdr = await secondAccount.getAddress();
    // must allow to transfer token
    await uAD.connect(thirdAccount).approve(routerAdr, ethers.utils.parseEther("10000"));
    await uGOV.connect(thirdAccount).approve(routerAdr, ethers.utils.parseEther("1000"));
    // If the liquidity is to be added to an ERC-20/ERC-20 pair, use addLiquidity.
    const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    await router
      .connect(thirdAccount)
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
    const UGOVPair = (await ethers.getContractAt("IUniswapV2Pair", await sushiUGOVPool.pair())) as IUniswapV2Pair;

    let uGOVId = 1;
    let uADId = 0;
    if ((await UGOVPair.token0()) !== uAD.address) {
      uADId = 1;
      uGOVId = 0;
    }
    const uGOVLPTotalSupplyBeforeDistribution = await UGOVPair.totalSupply();
    const zeroAdrBalBeforeBurnLiquidity = await UGOVPair.balanceOf(ethers.constants.AddressZero);
    const reservesBeforeBurn = await UGOVPair.getReserves();
    // distribute uAD
    await excessDollarsDistributor.distributeDollars();
    // 50% should go to the treasury
    const treasuryBalance = await uAD.balanceOf(treasuryAdr);
    expect(treasuryBalance).to.equal(fiftyPercent);
    // Check that 10% goes to uGOV-UAD LP buyBack and burn
    const reservesAfterBurn = await UGOVPair.getReserves();
    const remainingUAD = await uAD.balanceOf(excessDollarsDistributor.address);
    // we should have 5 more uAD because of the swap and ~5 more because of
    // the liquidity provided. It is not exactly 5 because the price moved because of
    // the swap
    expect(reservesAfterBurn[uADId]).to.equal((reservesBeforeBurn[uADId] as BigNumber).add(amount.mul(10).div(100)).sub(remainingUAD));
    // we should have 0 more uGOV
    expect(reservesAfterBurn[uGOVId]).to.equal(reservesBeforeBurn[uGOVId]);

    const uGOVLPTotalSupplyAfterDistribution = await UGOVPair.totalSupply();
    const zeroAdrBalAfterBurnLiquidity = await UGOVPair.balanceOf(ethers.constants.AddressZero);

    expect(uGOVLPTotalSupplyAfterDistribution.sub(uGOVLPTotalSupplyBeforeDistribution.add(zeroAdrBalAfterBurnLiquidity))).to.be.lt(
      ethers.utils.parseEther("0.0004")
    );
    expect(zeroAdrBalAfterBurnLiquidity).to.be.gt(zeroAdrBalBeforeBurnLiquidity);
    const scBalAfterBurnLiquidity = await UGOVPair.balanceOf(excessDollarsDistributor.address);
    expect(scBalAfterBurnLiquidity).to.equal(0);
    // 50% of UAD should have been deposited as liquidity to curve and transfered
    // to the bonding contract
    // calculate the amount of LP token to receive

    // no CRV tokens should be left
    const crvBalanceAfterAddLiquidity = await crvToken.balanceOf(excessDollarsDistributor.address);
    expect(crvBalanceAfterAddLiquidity).to.equal(0);
    // no LP tokens should be left
    const LPBalAfterAddLiquidity = await metaPool.balanceOf(excessDollarsDistributor.address);
    expect(LPBalAfterAddLiquidity).to.equal(0);
    // all the LP should have been transferred to the bonding contract
    const currentLPInBonding = await metaPool.balanceOf(bondingV2.address);
    const fourtyPercentAsLP = currentLPInBonding.sub(LPInBondingBeforeDistribute);

    expect(dyuAD2LP).to.be.lt(fourtyPercentAsLP);
    // 99.9 % precise
    const isPrecise = isAmountEquivalent(dyuAD2LP.toString(), fourtyPercentAsLP.toString(), "0.0007");
    expect(isPrecise).to.be.true;

    // some uAD is left because when we swap uAD for UGOV we change the price in
    // the sushi pool and then we can't add liquidity with all our uAD left
    excessDollarBalance = await uAD.balanceOf(excessDollarsDistributor.address);
    expect(excessDollarBalance).to.be.lt(ethers.utils.parseEther("0.02"));
  });
});
