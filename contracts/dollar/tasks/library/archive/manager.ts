import { Network } from "@ethersproject/networks/lib/types";
import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types/runtime";
import { UbiquityAlgorithmicDollarManager } from "../../../artifacts/types/UbiquityAlgorithmicDollarManager";

module.exports = {
  description: "Get info about manager contract's address",
  action:
    (): ActionType<any> =>
    async (_taskArgs, { ethers }) => {
      const network = (await ethers.provider.getNetwork()) as Network;
      const managerAdr = "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98";
      const debtCouponMgrAdr = "0x432120Ad63779897A424f7905BA000dF38A74554";
      if (network.name === "hardhat") {
        console.warn("You are running the   task with Hardhat network");
      }
      console.log(`net chainId: ${network.chainId}  `);
      const manager = (await ethers.getContractAt("UbiquityAlgorithmicDollarManager", managerAdr)) as UbiquityAlgorithmicDollarManager;

      const spreadsheet = {
        mgrtwapOracleAddress: await manager.twapOracleAddress(),
        mgrdebtCouponAddress: await manager.debtCouponAddress(),
        mgrDollarTokenAddress: await manager.dollarTokenAddress(),
        mgrcouponCalculatorAddress: await manager.couponCalculatorAddress(),
        mgrdollarMintingCalculatorAddress: await manager.dollarMintingCalculatorAddress(),
        mgrbondingShareAddress: await manager.bondingShareAddress(),
        mgrbondingContractAddress: await manager.bondingContractAddress(),
        mgrstableSwapMetaPoolAddress: await manager.stableSwapMetaPoolAddress(),
        mgrcurve3PoolTokenAddress: await manager.curve3PoolTokenAddress(),
        mgrtreasuryAddress: await manager.treasuryAddress(),
        mgruGOVTokenAddress: await manager.governanceTokenAddress(),
        mgrsushiSwapPoolAddress: await manager.sushiSwapPoolAddress(),
        mgrmasterChefAddress: await manager.masterChefAddress(),
        mgrformulasAddress: await manager.formulasAddress(),
        mgrautoRedeemTokenAddress: await manager.autoRedeemTokenAddress(),
        mgruarCalculatorAddress: await manager.uarCalculatorAddress(),
        mgrExcessDollarsDistributor: await manager.getExcessDollarsDistributor(debtCouponMgrAdr),
      };

      console.table(spreadsheet);
    },
};
