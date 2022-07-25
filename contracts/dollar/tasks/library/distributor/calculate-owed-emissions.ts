import "@nomiclabs/hardhat-waffle";
import erc20 from "@openzeppelin/contracts/build/contracts/ERC20.json";
import "hardhat-deploy";
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";
import { ERC20 } from "../../../artifacts/types/ERC20";
// import tranches from "../../distributor-transactions.json"; // TODO: pass these in as arguments
// import addressBook from "./distributor/investors.json"; // TODO: pass these in as arguments
import { getTotalSupply } from "./owed-emissions-library/getTotalSupply";
import { sumTotalSentToContacts } from "./owed-emissions-library/sumTotalSentToContacts";
import { vestingMath } from "./owed-emissions-library/vestingMath";
import { TaskArgs } from "./utils/distributor-types";

const ubiquityGovernanceTokenAddress = "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0";

// module.exports = {
//   description: "Calculates the amount of owed UBQ emissions since the beginning of the vesting schedule", // { "percent": number, "address": string, "name": string }[]
//   optionalParams: {
//     token: ["Token address", ubiquityGovernanceTokenAddress, types.string],
//   },
//   action: (): ActionType<any> => calculateOwedUbqEmissions,
// };

// TODO: need to consolidate tasks together
// currently you must run the following in order

// yarn hardhat distributor --investors <full path to (investors.json)>
// yarn hardhat calculate-owed-emissions

export async function calculateOwedUbqEmissions(taskArgs: TaskArgs, hre: HardhatRuntimeEnvironment) {
  const totals = await sumTotalSentToContacts();

  let cacheTotalSupply: number;
  if (ubiquityGovernanceTokenAddress) {
    const token = (await hre.ethers.getContractAt(erc20.abi, ubiquityGovernanceTokenAddress)) as ERC20;
    const totalSupply = hre.ethers.utils.formatEther(await token.totalSupply());
    cacheTotalSupply = parseInt(totalSupply);
  }
  cacheTotalSupply = await getTotalSupply(taskArgs, hre);

  const toSend = await totals.map((contact: ContactWithTransfers) => {
    const shouldGet = vestingMath({
      investorAllocationPercentage: contact.percent,
      totalSupplyCached: cacheTotalSupply,
    });

    return Object.assign(
      {
        owed: shouldGet - contact.transferred,
      },
      contact
    );
  });

  console.log(toSend);
  return toSend;
}

type AddressBookContact = typeof addressBook[0];
export interface ContactWithTransfers extends AddressBookContact {
  transferred: number;
  transactions: string[];
}
