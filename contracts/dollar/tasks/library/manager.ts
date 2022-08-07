import "@nomiclabs/hardhat-waffle";
import { ActionType, HardhatRuntimeEnvironment } from "hardhat/types";
import { UbiquityAlgorithmicDollarManager } from "../../artifacts/types/UbiquityAlgorithmicDollarManager";
// This file is only here to make interacting with the Dapp easier,
// feel free to ignore it if you don't need it.

export const description = "Get info about manager contract's address";
export const action = (): ActionType<any> => async (_taskArgs, { ethers }: HardhatRuntimeEnvironment) => {
  const net = await ethers.provider.getNetwork();
  const managerAdr = "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98";
  const debtCouponMgrAdr = "0x432120Ad63779897A424f7905BA000dF38A74554";
  if (net.name === "hardhat") {
    console.warn("You are running the   task with Hardhat network");
  }
  console.log(`net chainId: ${net.chainId}  `);
  const manager = (await ethers.getContractAt("UbiquityAlgorithmicDollarManager", managerAdr)) as UbiquityAlgorithmicDollarManager;
  const mgrtwapOracleAddress = await manager.twapOracleAddress();
  const mgrdebtCouponAddress = await manager.debtCouponAddress();
  const mgrDollarTokenAddress = await manager.dollarTokenAddress();
  const mgrcouponCalculatorAddress = await manager.couponCalculatorAddress();
  const mgrdollarMintingCalculatorAddress = await manager.dollarMintingCalculatorAddress();
  const mgrbondingShareAddress = await manager.bondingShareAddress();
  const mgrbondingContractAddress = await manager.bondingContractAddress();
  const mgrstableSwapMetaPoolAddress = await manager.stableSwapMetaPoolAddress();
  const mgrcurve3PoolTokenAddress = await manager.curve3PoolTokenAddress(); // 3CRV
  const mgrtreasuryAddress = await manager.treasuryAddress();
  const mgruGOVTokenAddress = await manager.governanceTokenAddress();
  const mgrsushiSwapPoolAddress = await manager.sushiSwapPoolAddress(); // sushi pool uAD-uGOV
  const mgrmasterChefAddress = await manager.masterChefAddress();
  const mgrformulasAddress = await manager.formulasAddress();
  const mgrautoRedeemTokenAddress = await manager.autoRedeemTokenAddress(); // uAR
  const mgruarCalculatorAddress = await manager.uarCalculatorAddress(); // uAR calculator

  const mgrExcessDollarsDistributor = await manager.getExcessDollarsDistributor(debtCouponMgrAdr);
  console.log(`
      ****
      debtCouponMgr:${debtCouponMgrAdr}
      manager ALL VARS:
      mgrtwapOracleAddress:${mgrtwapOracleAddress}
      debtCouponAddress:${mgrdebtCouponAddress}
      uADTokenAddress:${mgrDollarTokenAddress}
      couponCalculatorAddress:${mgrcouponCalculatorAddress}
      dollarMintingCalculatorAddress:${mgrdollarMintingCalculatorAddress}
      bondingShareAddress:${mgrbondingShareAddress}
      bondingContractAddress:${mgrbondingContractAddress}
      stableSwapMetaPoolAddress:${mgrstableSwapMetaPoolAddress}
      curve3PoolTokenAddress:${mgrcurve3PoolTokenAddress}
      treasuryAddress:${mgrtreasuryAddress}
      uGOVTokenAddress:${mgruGOVTokenAddress}
      sushiSwapPoolAddress:${mgrsushiSwapPoolAddress}
      masterChefAddress:${mgrmasterChefAddress}
      formulasAddress:${mgrformulasAddress}
      autoRedeemTokenAddress:${mgrautoRedeemTokenAddress}
      uarCalculatorAddress:${mgruarCalculatorAddress}
      ExcessDollarsDistributor:${mgrExcessDollarsDistributor}
      `);
};
