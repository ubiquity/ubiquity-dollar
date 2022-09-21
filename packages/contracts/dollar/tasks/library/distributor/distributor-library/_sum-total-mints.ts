// import "@nomiclabs/hardhat-waffle";
// import "hardhat-deploy";
// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { ActionType } from "hardhat/types/runtime";
// import mintTransactionEvents from "../../../../mints-histories.json"; // TODO: pass these in as arguments
// import { TaskArgs } from "./distributor-types";

// module.exports = {
//   description: "total the amount minted from a list of transaction events",
//   action: (): ActionType<any> => sumTotalMints,
// };

// export async function sumTotalMints(taskArgs: TaskArgs, hre: HardhatRuntimeEnvironment) {
//   let totals = 0;
//   const buffer = [] as any[];
//   mintTransactionEvents.forEach(function processor(tx) {
//     const forceTypingOfLastArg = tx.events.args[2] as {
//       type: "BigNumber";
//       hex: "0x2565ca8e8262f131e0dc";
//     };

//     const decimal = parseInt(forceTypingOfLastArg.hex);
//     totals += decimal;
//     buffer.push({
//       transaction: tx.log.transactionHash,
//       amount: decimal / 1e18,
//     });
//   });

//   const humanReadable = totals / 1e18;
//   console.table(buffer);
//   console.table({ totals: humanReadable });
//   return humanReadable;
// }
