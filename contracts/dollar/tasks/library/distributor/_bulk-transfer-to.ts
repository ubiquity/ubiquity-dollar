// import "@nomiclabs/hardhat-waffle";
// import { Wallet } from "ethers";
// import "hardhat-deploy";
// import { ActionType } from "hardhat/types/runtime";
// import { impersonate } from "./bulk-transfer-to-library/impersonate";

// let distributor = "0x445115D7c301E6cC3B5A21cE86ffCd8Df6EaAad9";

// if (process.env.UBQ_DISTRIBUTOR) {
//   distributor = new Wallet(process.env.UBQ_DISTRIBUTOR).address;
// }

// export const addressBook = {
//   token: "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0", // Ubiquity Governance
//   sender: distributor,
//   receiver: "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd", // Investor
// };

// export const description = "Distributes investor emissions";
// export const params = {
//   receiver: "Account thats receiving the tokens",
// };
// export const optionalParams = {
//   token: ["Ubiquity governance token address", addressBook.token],
//   sender: ["Account thats distributing the tokens", addressBook.sender],
//   // receiver: ["Account thats receiving the tokens", addressBook.receiver],
// };
// export const action = (): ActionType<any> => impersonate;
