import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import { ICurveFactory } from "../artifacts/types/ICurveFactory";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { DollarMintingCalculator } from "../artifacts/types/DollarMintingCalculator";
// This file is only here to make interacting with the Dapp easier,
// feel free to ignore it if you don't need it.

task("price", "get information about UAD price").setAction(
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

    let curveFactory = "";
    let DAI = "";
    let USDC = "";
    let USDT = "";
    let curve3CrvToken = "";
    ({ curveFactory, DAI, USDC, USDT, curve3CrvToken } =
      await getNamedAccounts());

    const curvePoolFactory = (await ethers.getContractAt(
      "ICurveFactory",
      curveFactory
    )) as ICurveFactory;

    const indices = await curvePoolFactory.get_coin_indices(
      metaPool.address,
      DAI,
      USDT
    );

    const indices2 = await curvePoolFactory.get_coin_indices(
      metaPool.address,
      uAD.address,
      USDC
    );
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

    console.log(`
    1 DAI => ${ethers.utils.formatUnits(dyDAI2USDT, "mwei")} USDT
    1 uAD => ${ethers.utils.formatUnits(dyuAD2USDC, "mwei")} USDC
    1 uAD => ${ethers.utils.formatEther(dyuAD2DAI)} DAI
    1 uAD => ${ethers.utils.formatUnits(dyuAD2USDT, "mwei")} USDT
      `);

    const mgrtwapOracleAddress = await manager.twapOracleAddress();
    const twapOracle = (await ethers.getContractAt(
      "TWAPOracle",
      mgrtwapOracleAddress
    )) as TWAPOracle;
    const oraclePriceuAD = await twapOracle.consult(uAD.address);
    const oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
    console.log(`---TWAPOracle:${mgrtwapOracleAddress}  `);
    console.log(`
    TWAP PRICE
    1 uAD => ${ethers.utils.formatEther(oraclePriceuAD)} 3CRV
    1 3CRV => ${ethers.utils.formatEther(oraclePrice3Crv)} uAD
      `);
    if (oraclePriceuAD.gt(ethers.utils.parseEther("1"))) {
      const dollarMintingCalculatorAddress =
        await manager.dollarMintingCalculatorAddress();
      const dollarMintingCalculator = (await ethers.getContractAt(
        "DollarMintingCalculator",
        dollarMintingCalculatorAddress
      )) as DollarMintingCalculator;
      const dollarsToMint = await dollarMintingCalculator.getDollarsToMint();

      console.log(`
      Dollar to be minted
      ${ethers.utils.formatEther(dollarsToMint)} uAD
        `);
    }
  }
);
