import "@nomiclabs/hardhat-waffle";

import { ActionType } from "hardhat/types";
import { CurveUADIncentive } from "../../artifacts/types/CurveUADIncentive";
import { UbiquityAlgorithmicDollar } from "../../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityAlgorithmicDollarManager } from "../../artifacts/types/UbiquityAlgorithmicDollarManager";

export const description = "Sends ETH and tokens to an address";
export const action = (): ActionType<any> => async (taskArgs: { receiver: string; manager: string }, { ethers }) => {
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

  const uAD = (await ethers.getContractAt("UbiquityAlgorithmicDollar", uADAdr)) as UbiquityAlgorithmicDollar;
  const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
  const incentive = await uAD.incentiveContract(metaPoolAddr);
  const curveIncentive = (await ethers.getContractAt("CurveUADIncentive", incentive)) as CurveUADIncentive;

  console.log("curveIncentive   at:", incentive);

  const isSellPenaltyOn = await curveIncentive.isSellPenaltyOn();
  const isBuyIncentiveOn = await curveIncentive.isBuyIncentiveOn();
  console.log(`
    isSellPenaltyOn: ${isSellPenaltyOn ? "True" : "False"}
    isBuyIncentiveOn: ${isBuyIncentiveOn ? "True" : "False"}
      `);
};
