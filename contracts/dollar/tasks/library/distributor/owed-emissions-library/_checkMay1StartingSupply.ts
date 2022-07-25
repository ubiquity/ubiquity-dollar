// import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";
// import { vestingRange } from "..";
// import { contracts } from "../../../../../fixtures/ubiquity-dollar-deployment.json";
// import { UbiquityGovernance } from "../../../../artifacts/types/UbiquityGovernance";
// import blockHeightDater from "../utils/block-height-dater";
// import { verifyMinMaxBlockHeight } from "../utils/distributor-helpers";
// import { setBlockHeight } from "./setBlockHeight";

// async function checkMay1StartingSupply(hre: HardhatRuntimeEnvironment) {
//   const timestampsDated = await blockHeightDater(vestingRange); // "2022-05-01T00:00:00.000Z" // this should only be one date instead of a range (two)
//   const range = await verifyMinMaxBlockHeight(timestampsDated);
//   const startingBlock = range[0]?.block;
//   await setBlockHeight(hre.network, startingBlock);
//   const ubqToken = (await getContractInstance("UbiquityGovernance")) as UbiquityGovernance;
//   const totalStartingSupply = hre.ethers.utils.formatEther(await ubqToken.totalSupply());
//   return totalStartingSupply; // 14688630

//   async function getContractInstance(name: keyof typeof contracts) {
//     if (!contracts[name]) {
//       throw new Error(`Contract ${name} not found in list ${Object.keys(contracts)}`);
//     }
//     return await hre.ethers.getContractAt(name, contracts[name].address);
//   }
// }
