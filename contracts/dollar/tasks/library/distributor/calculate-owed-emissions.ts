import "@nomiclabs/hardhat-waffle";
import erc20 from "@openzeppelin/contracts/build/contracts/ERC20.json";
import "hardhat-deploy";
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";
import { ERC20 } from "../../../artifacts/types/ERC20";

import { Investor, InvestorWithTransfers } from "./distributor-library/investor-types";
import { Tranche } from "./distributor-library/log-filters/transfers-to-investors";
import { getTotalSupply } from "./owed-emissions-library/getTotalSupply";
import { sumTotalSentToContacts } from "./owed-emissions-library/sumTotalSentToContacts";
import { vestingMath } from "./owed-emissions-library/vestingMath";

const ubiquityGovernanceTokenAddress = "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0";

// TODO: need to consolidate tasks together
// currently you must run the following in order

// yarn hardhat distributor --investors <full path to (investors.json)>
// yarn hardhat calculate-owed-emissions

export async function calculateOwedUbqEmissions(
  investors: Investor[],
  tranches: Tranche[],
  hre: HardhatRuntimeEnvironment
): Promise<({ owed: number } & InvestorWithTransfers)[]> {
  const totals = await sumTotalSentToContacts(investors, tranches);

  let cacheTotalSupply: number;
  if (ubiquityGovernanceTokenAddress) {
    const token = (await hre.ethers.getContractAt(erc20.abi, ubiquityGovernanceTokenAddress)) as ERC20;
    const totalSupply = hre.ethers.utils.formatEther(await token.totalSupply());
    cacheTotalSupply = parseInt(totalSupply);
  }
  cacheTotalSupply = await getTotalSupply(hre);

  const toSend = totals.map((investor: InvestorWithTransfers) => {
    const shouldGet = vestingMath({ investorAllocationPercentage: investor.percent, totalSupplyCached: cacheTotalSupply });
    return Object.assign({ owed: shouldGet - investor.transferred }, investor);
  });

  return toSend;
}
