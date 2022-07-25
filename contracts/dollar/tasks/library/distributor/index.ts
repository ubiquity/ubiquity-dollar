import { HardhatRuntimeEnvironment } from "hardhat/types";
import { calculateOwedUbqEmissions } from "./calculate-owed-emissions";
import { getInvestors } from "./distributor-library/getInvestors";
import transferFilter from "./distributor-library/log-filters/transfers";
import { Tranche, transfersToInvestorsFilterWrapper } from "./distributor-library/log-filters/transfers-to-investors";
import { readContractTransactionHistory } from "./distributor-library/read-contract-transaction-history";
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
  console.log({ investors });

  const transactionHistories = await readContractTransactionHistory(taskArgs.token, vestingRange);
  console.log({ transactionHistories });

  const transfersToAnybody = transactionHistories.filter(transferFilter);
  const transfersToInvestorsFilter = transfersToInvestorsFilterWrapper(investors);

  const tranches = transfersToAnybody.map(transfersToInvestorsFilter).filter(Boolean) as Tranche[];
  console.log({ tranches });

  const owed = await calculateOwedUbqEmissions(investors, tranches, hre);
  console.log({ owed });

  return owed;
}
