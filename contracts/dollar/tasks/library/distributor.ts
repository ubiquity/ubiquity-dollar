import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import { types } from "hardhat/config";
import { ActionType } from "hardhat/types/runtime";
import { _distributor } from "./distributor/";

// yarn hardhat distributor --investors ./investors.json

const ubiquityGovernanceTokenAddress = "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0";

export const description = "Distributes investor emissions to a list of investors"; // { "percent": number, "address": string, "name": string }[]
export const params = {
  investors: "A path to a json file containing a list of investors",
};
export const optionalParams = {
  token: ["Token address", ubiquityGovernanceTokenAddress, types.string],
};
export const action = (): ActionType<any> => _distributor;
