import { BigNumber, Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { expect } from "chai";
import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { ERC20 } from "../artifacts/types/ERC20";

import { IUniswapV2Router02 } from "../artifacts/types/IUniswapV2Router02";
import { IUniswapV2Pair } from "../artifacts/types/IUniswapV2Pair";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { resetFork } from "./utils/hardhatNode";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { ExcessDollarsDistributor } from "../artifacts/types/ExcessDollarsDistributor";

describe("ExcessDollarsDistributor", () => {
  let metaPool: IMetaPool;
  let manager: UbiquityAlgorithmicDollarManager;
  let admin: Signer;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let treasury: Signer;
  let bondingContractAdr: string;
  let bondingContract: Signer;
  let uAD: UbiquityAlgorithmicDollar;
  let crvToken: ERC20;
  let curveFactory: string;
  let curve3CrvBasePool: string;
  let curve3CrvToken: string;
  let curveWhaleAddress: string;
  let curveWhale: Signer;
  let uGOV: UbiquityGovernance;
  let sushiUGOVPool: SushiSwapPool;
  let treasuryAdr: string;
  let excessDollarsDistributor: ExcessDollarsDistributor;
  const routerAdr = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F"; // SushiV2Router02
  let router: IUniswapV2Router02;

  beforeEach(async () => {
    // list of accounts
    ({ curveFactory, curve3CrvBasePool, curve3CrvToken, curveWhaleAddress } = await getNamedAccounts());
    [admin, secondAccount, thirdAccount, treasury, bondingContract] = await ethers.getSigners();
    await resetFork(12592661);
    router = (await ethers.getContractAt("IUniswapV2Router02", routerAdr)) as IUniswapV2Router02;

    // deploy manager
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    const uADFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await uADFactory.deploy(manager.address)) as UbiquityAlgorithmicDollar;
    await manager.setDollarTokenAddress(uAD.address);
    const uGOVFactory = await ethers.getContractFactory("UbiquityGovernance");
    uGOV = (await uGOVFactory.deploy(manager.address)) as UbiquityGovernance;
    await manager.setGovernanceTokenAddress(uGOV.address);
    // set twap Oracle Address
    crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;

    // to deploy the stableswap pool we need 3CRV and uAD
    // kindly ask a whale to give us some 3CRV
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [curveWhaleAddress],
    });
    curveWhale = ethers.provider.getSigner(curveWhaleAddress);
    await crvToken.connect(curveWhale).transfer(manager.address, ethers.utils.parseEther("10000"));
    // just mint som uAD
    // mint 10000 uAD each for admin, manager and secondAccount
    const mintings = [await secondAccount.getAddress(), await thirdAccount.getAddress(), manager.address].map(
      async (signer): Promise<void> => {
        await uAD.mint(signer, ethers.utils.parseEther("10000"));
      }
    );
    await Promise.all(mintings);

    await uGOV.mint(await thirdAccount.getAddress(), ethers.utils.parseEther("1000"));

    await manager.deployStableSwapPool(curveFactory, curve3CrvBasePool, crvToken.address, 10, 4000000);
    // setup the oracle
    const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
    metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;

    const excessDollarsDistributorFactory = await ethers.getContractFactory("ExcessDollarsDistributor");
    excessDollarsDistributor = (await excessDollarsDistributorFactory.deploy(manager.address)) as ExcessDollarsDistributor;

    // set treasury,uGOV-UAD LP (TODO) and Bonding Cntract address needed for excessDollarsDistributor
    treasuryAdr = await treasury.getAddress();
    await manager.setTreasuryAddress(treasuryAdr);

    bondingContractAdr = await bondingContract.getAddress();
    await manager.setBondingContractAddress(bondingContractAdr);

    const sushiFactory = await ethers.getContractFactory("SushiSwapPool");
    sushiUGOVPool = (await sushiFactory.deploy(manager.address)) as SushiSwapPool;
    await manager.setSushiSwapPoolAddress(sushiUGOVPool.address);
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
    const dyuAD2LP = await metaPool["calc_token_amount(uint256[2],bool)"]([0, dyuADto3CRV], true);

    const LPInBondingBeforeDistribute = await metaPool.balanceOf(bondingContractAdr);
    expect(LPInBondingBeforeDistribute).to.equal(0);
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
    const fourtyPercentAsLP = await metaPool.balanceOf(bondingContractAdr);

    expect(dyuAD2LP).to.be.lt(fourtyPercentAsLP);
    // 99.9 % precise
    expect(dyuAD2LP).to.be.gt(fourtyPercentAsLP.mul(999).div(1000));

    // some uAD is left because when we swap uAD for UGOV we change the price in
    // the sushi pool and then we can't add liquidity with all our uAD left
    excessDollarBalance = await uAD.balanceOf(excessDollarsDistributor.address);
    expect(excessDollarBalance).to.equal(BigNumber.from("12607400750000001"));
  });

  it.skip("distributeDollars should work with limited liquidity", async () => {
    // drain all uad from the pool
    const dyuAD2DAIBefore = await metaPool["get_dy_underlying(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));

    console.log(`
    1 uAD => ${ethers.utils.formatEther(dyuAD2DAIBefore)} DAI
      `);

    const balancesUADBefore = await metaPool.balances(0);
    console.log("balancesUADBefore", ethers.utils.formatEther(balancesUADBefore));
    const balancesCRVBefore = await metaPool.balances(1);
    console.log("balancesCRVBefore", ethers.utils.formatEther(balancesCRVBefore));
    const lpBalance = await metaPool.balanceOf(await admin.getAddress());
    const LPamountToWithdraw = lpBalance.sub(lpBalance.div("10"));
    console.log("before dyuAD");
    const dyuAD = await metaPool["calc_withdraw_one_coin(uint256,int128)"](LPamountToWithdraw, 1);
    console.log("before remove_liquidity_one_coin");
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](LPamountToWithdraw, 1, dyuAD.mul(99).div(100));
    console.log("after remove_liquidity_one_coin");
    const balancesUADAfter = await metaPool.balances(0);
    console.log("balancesUADAfter", ethers.utils.formatEther(balancesUADAfter));
    const balancesCRVAfter = await metaPool.balances(1);
    console.log("balancesCRVAfter", ethers.utils.formatEther(balancesCRVAfter));
    const dyuAD2DAIAfter = await metaPool["get_dy_underlying(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    console.log("after get_dy_underlying");
    console.log(`
    1 uAD => ${ethers.utils.formatEther(dyuAD2DAIAfter)} DAI
      `);
    // simulate distribution of uAD to ExcessDollarDistributor
    const amount = ethers.utils.parseEther("10000");
    const tenPercent = amount.mul(10).div(100);
    const fiftyPercent = amount.div(2);
    await uAD.connect(secondAccount).transfer(excessDollarsDistributor.address, amount);
    let excessDollarBalance = await uAD.balanceOf(excessDollarsDistributor.address);

    console.log("before dyuADto3CRV");
    expect(excessDollarBalance).to.equal(amount);
    // amount of LP token to send to bonding contract
    const dyuADto3CRV = await metaPool["get_dy(int128,int128,uint256)"](0, 1, amount.sub(fiftyPercent).sub(tenPercent));
    const dyuAD2LP = await metaPool["calc_token_amount(uint256[2],bool)"]([0, dyuADto3CRV], true);
    console.log("dyuADto3CRV", ethers.utils.formatEther(dyuADto3CRV));
    console.log("dyuAD2LP", ethers.utils.formatEther(dyuAD2LP));
    const LPInBondingBeforeDistribute = await metaPool.balanceOf(bondingContractAdr);
    expect(LPInBondingBeforeDistribute).to.equal(0);
    // provide liquidity to the pair uAD-UGOV so that 1 uGOV = 10 uAD
    const secondAccAdr = await secondAccount.getAddress();
    // must allow to transfer token
    await uAD.connect(thirdAccount).approve(routerAdr, ethers.utils.parseEther("10000"));
    await uGOV.connect(thirdAccount).approve(routerAdr, ethers.utils.parseEther("1000"));
    // If the liquidity is to be added to an ERC-20/ERC-20 pair, use addLiquidity.
    const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    console.log("before addLiquidity");
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

    let uADId = 0;
    if ((await UGOVPair.token0()) !== uAD.address) {
      uADId = 1;
    }
    const uGOVLPTotalSupplyBeforeDistribution = await UGOVPair.totalSupply();
    const zeroAdrBalBeforeBurnLiquidity = await UGOVPair.balanceOf(ethers.constants.AddressZero);
    const reservesBeforeBurn = await UGOVPair.getReserves();

    const fourtyPercentAsLPBefore = await metaPool.balanceOf(bondingContractAdr);
    console.log("before excess");
    // distribute uAD
    await excessDollarsDistributor.distributeDollars();
    console.log("after excess");
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
    //   expect(reservesAfterBurn[uGOVId]).to.equal(reservesBeforeBurn[uGOVId]);

    const uGOVLPTotalSupplyAfterDistribution = await UGOVPair.totalSupply();
    const zeroAdrBalAfterBurnLiquidity = await UGOVPair.balanceOf(ethers.constants.AddressZero);

    expect(uGOVLPTotalSupplyAfterDistribution.sub(uGOVLPTotalSupplyBeforeDistribution.add(zeroAdrBalAfterBurnLiquidity))).to.be.lt(
      ethers.utils.parseEther("0.04")
    );
    expect(zeroAdrBalAfterBurnLiquidity).to.be.gt(zeroAdrBalBeforeBurnLiquidity);
    const scBalAfterBurnLiquidity = await UGOVPair.balanceOf(excessDollarsDistributor.address);
    expect(scBalAfterBurnLiquidity).to.equal(0);
    // 50% of UAD should have been deposited as liquidity to curve and transferred
    // to the bonding contract
    // calculate the amount of LP token to receive

    // no CRV tokens should be left
    const crvBalanceAfterAddLiquidity = await crvToken.balanceOf(excessDollarsDistributor.address);
    expect(crvBalanceAfterAddLiquidity).to.equal(0);
    // no LP tokens should be left
    const LPBalAfterAddLiquidity = await metaPool.balanceOf(excessDollarsDistributor.address);
    expect(LPBalAfterAddLiquidity).to.equal(0);
    // all the LP should have been transferred to the bonding contract
    const fourtyPercentAsLP = await metaPool.balanceOf(bondingContractAdr);

    expect(dyuAD2LP).to.be.lt(fourtyPercentAsLP);
    console.log("dyuAD2LP", ethers.utils.formatEther(dyuAD2LP));
    console.log("fourtyPercentAsLP", ethers.utils.formatEther(fourtyPercentAsLP));
    console.log("fourtyPercentAsLPBefore", ethers.utils.formatEther(fourtyPercentAsLPBefore));
    // 99.9 % precise
    expect(dyuAD2LP).to.be.gt(fourtyPercentAsLP.mul(97).div(100));

    // some uAD is left because when we swap uAD for UGOV we change the price in
    // the sushi pool and then we can't add liquidity with all our uAD left
    excessDollarBalance = await uAD.balanceOf(excessDollarsDistributor.address);
    expect(excessDollarBalance).to.equal(BigNumber.from("12607400750000001"));
  });
});
