import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";

import { ActionType } from "hardhat/types";

import { types } from "hardhat/config";
import faucet from "./faucet/";

export const accountWithWithdrawableBond = "0x4007ce2083c7f3e18097aeb3a39bb8ec149a341d";

export const description = "Sends ETH and tokens to an address";
export const optionalParam = {
  receiver: ["The address that will receive them", accountWithWithdrawableBond, types.string],
  manager: ["The address of uAD Manager", "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98", types.string],
};
export const action = (): ActionType<any> => faucet;
