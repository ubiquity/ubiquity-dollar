import * as fs from "fs";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getRecipients } from "./utils/distributor-helpers";
import { TaskArgs } from "./utils/distributor-types";
import { readContractTransactionHistory } from "./utils/read-contract-transaction-history";
import mintFilter from "./log-filters/mints";
import transferFilter from "./log-filters/transfers";
import { transfersToContactsFilter } from "./log-filters/transfers-to-contacts";

export const vestingRange = ["2022-05-01T00:00:00.000Z", "2024-05-01T00:00:00.000Z"];

/**
 * distributor needs to do the following:
 * * 1. load the investors from a json file
 * * 2. verify the amount sent to each recipient within the vesting range
 * * 3. distribute according to the vesting schedule to each recipient, and subtract the amount already sent
 * * 4. transfer the tokens to each recipient
 */
export async function _distributor(taskArgs: TaskArgs, hre: HardhatRuntimeEnvironment) {
  const investors = await getRecipients(taskArgs.investors); // 1

  const transactionHistories = await readContractTransactionHistory(taskArgs.token, vestingRange);
  fs.writeFileSync("./transaction-histories.json", JSON.stringify(transactionHistories, null, 2));

  const transfersOnly = transactionHistories.filter(transferFilter);

  // const mintsOnly = transactionHistories.filter(mintFilter);
  // fs.writeFileSync("./mints-histories.json", JSON.stringify(mintsOnly, null, 2));

  const transfersToContactsOnly = transfersOnly.map(transfersToContactsFilter(investors)).filter(Boolean);
  fs.writeFileSync("./distributor-transactions.json", JSON.stringify(transfersToContactsOnly, null, 2));
}
