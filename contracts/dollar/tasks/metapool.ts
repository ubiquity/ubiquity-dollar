import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import { ICurveFactory } from "../artifacts/types/ICurveFactory";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { IMetaPool } from "../artifacts/types/IMetaPool";
// This file is only here to make interacting with the Dapp easier,
// feel free to ignore it if you don't need it.

task("metapool", "Get info about our curve metapool").setAction(
  async (
    taskArgs: { receiver: string; manager: string },
    { ethers, getNamedAccounts }
  ) => {
    const net = await ethers.provider.getNetwork();

    if (net.name === "hardhat") {
      console.warn("You are running the   task with Hardhat network");
    }
    console.log(`net chainId: ${net.chainId}  `);
    const manager = (await ethers.getContractAt(
      "UbiquityAlgorithmicDollarManager",
      "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98"
    )) as UbiquityAlgorithmicDollarManager;
    const uADAdr = await manager.dollarTokenAddress();

    const uAD = (await ethers.getContractAt(
      "UbiquityAlgorithmicDollar",
      uADAdr
    )) as UbiquityAlgorithmicDollar;
    const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
    console.log(`---metaPoolAddr:${metaPoolAddr}  `);
    const metaPool = (await ethers.getContractAt(
      "IMetaPool",
      metaPoolAddr
    )) as IMetaPool;
    const bondingAddr = await manager.bondingContractAddress();
    console.log(`---bondingAddr:${bondingAddr}  `);
    const bondingBal = await metaPool.balanceOf(bondingAddr);
    console.log(`
    Bonding Balance:${ethers.utils.formatEther(bondingBal)} LP
      `);
    let curveFactory = "";
    let DAI = "";
    let USDC = "";
    let USDT = "";

    ({ curveFactory, DAI, USDC, USDT } = await getNamedAccounts());

    const curvePoolFactory = (await ethers.getContractAt(
      "ICurveFactory",
      curveFactory
    )) as ICurveFactory;

    const pool0UADbal = await metaPool.balances(0);
    const pool1CRVbal = await metaPool.balances(1);

    console.log(`
    pool0UADbal:${ethers.utils.formatEther(pool0UADbal)}
    pool1CRVbal:${ethers.utils.formatEther(pool1CRVbal)}
      `);
    const rates = await curvePoolFactory.get_rates(metaPool.address);
    console.log(`
      rates
      0:${ethers.utils.formatEther(rates[0])}
      1:${ethers.utils.formatEther(rates[1])}
        `);
    const underBalances = await curvePoolFactory.get_underlying_balances(
      metaPool.address
    );

    console.log(`
    underBalances
    0:${ethers.utils.formatEther(underBalances[0])}
    1:${ethers.utils.formatEther(underBalances[1])}
    2:${ethers.utils.formatUnits(underBalances[2], "mwei")}
    3:${ethers.utils.formatUnits(underBalances[3], "mwei")}
        `);
    const indices = await curvePoolFactory.get_coin_indices(
      metaPool.address,
      DAI,
      USDT
    );
    console.log(`
    DAI indices:${indices[0].toString()}
    USDT indices:${indices[1].toString()}  `);

    const indices2 = await curvePoolFactory.get_coin_indices(
      metaPool.address,
      uAD.address,
      USDC
    );
    console.log(`
    uAD indices:${indices2[0].toString()}
    USDC indices:${indices2[1].toString()}  `);
    const dyDAI2USDT = await metaPool[
      "get_dy_underlying(int128,int128,uint256)"
    ](indices[0], indices[1], ethers.utils.parseEther("1"));

    const dyuAD2USDC = await metaPool[
      "get_dy_underlying(int128,int128,uint256)"
    ](indices2[0], indices2[1], ethers.utils.parseEther("1"));

    const dyuAD2DAI = await metaPool[
      "get_dy_underlying(int128,int128,uint256)"
    ](indices2[0], indices[0], ethers.utils.parseEther("1"));

    const dyuAD2USDT = await metaPool[
      "get_dy_underlying(int128,int128,uint256)"
    ](indices2[0], indices[1], ethers.utils.parseEther("1"));
    const decimals = await curvePoolFactory.get_underlying_decimals(
      metaPool.address
    );
    console.log(`
    uAD decimals : ${decimals[0].toString()}
    DAI decimals : ${decimals[1].toString()}
    USDC decimals : ${decimals[2].toString()}
    USDT decimals : ${decimals[3].toString()}
    `);

    console.log(`
    1 DAI => ${ethers.utils.formatUnits(dyDAI2USDT, "mwei")} USDT
    1 uAD => ${ethers.utils.formatUnits(dyuAD2USDC, "mwei")} USDC
    1 uAD => ${ethers.utils.formatEther(dyuAD2DAI)} DAI
    1 uAD => ${ethers.utils.formatUnits(dyuAD2USDT, "mwei")} USDT
      `);
  }
);
