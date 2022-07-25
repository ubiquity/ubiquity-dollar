import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Tranche, transfersToInvestorsFilterWrapper } from "./distributor-library/log-filters/transfers-to-investors";
import { readContractTransactionHistory } from "./distributor-library/read-contract-transaction-history";
import transferFilter from "./distributor-library/log-filters/transfers";
import { calculateOwedUbqEmissions } from "./calculate-owed-emissions";
import { getInvestors } from "./distributor-library/getInvestors";
const vestingRange = ["2022-05-01T00:00:00.000Z", "2024-05-01T00:00:00.000Z"];

/**
 * distributor needs to do the following:
 * * 1. load the investors from a json file
 * * 2. verify the amount sent to each recipient within the vesting range
 * * 3. distribute according to the vesting schedule to each recipient, and subtract the amount already sent
 * * 4. transfer the tokens to each recipient
 */

interface TaskArgs {
  investors: string; // path to json file containing a list of investors
  token: string; // address of the token
}

export async function _distributor(taskArgs: TaskArgs, hre: HardhatRuntimeEnvironment) {
  const investors = await getInvestors(taskArgs.investors); // 1

  const transactionHistories = await readContractTransactionHistory(taskArgs.token, vestingRange);
  // fs.writeFileSync("./transaction-histories.json", JSON.stringify(transactionHistories, null, 2));

  const transfersToAnybody = transactionHistories.filter(transferFilter);
  const transfersToInvestorsFilter = transfersToInvestorsFilterWrapper(investors);

  const transfersToInvestors = transfersToAnybody.map(transfersToInvestorsFilter).filter(Boolean) as Tranche[];
  const distributorTransactions = transfersToInvestors;
  const tranches = distributorTransactions;

  calculateOwedUbqEmissions(investors, tranches, hre);

  // fs.writeFileSync("./distributor-transactions.json", JSON.stringify(transfersToContactsOnly, null, 2));
}
