import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import { types } from "hardhat/config";
import { ActionType } from "hardhat/types/runtime";
import { _distributor as action } from "./distributor/";

// yarn hardhat distributor --investors ./investors.json

const ubiquityGovernanceTokenAddress = "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0";

module.exports = {
  description: "Distributes investor emissions to a list of investors", // { "percent": number, "address": string, "name": string }[]
  params: {
    investors: "A path to a json file containing a list of investors",
  },
  optionalParams: {
    token: ["Token address", ubiquityGovernanceTokenAddress, types.string],
  },
  action: (): ActionType<any> => action,
};
