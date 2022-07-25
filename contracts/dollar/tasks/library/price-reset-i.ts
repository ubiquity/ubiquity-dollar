import "@nomiclabs/hardhat-waffle";
import { types } from "hardhat/config";
import { priceResetter } from "./price-reset-i/index";

export interface TaskArgs {
  amount: string;
  pushHigher: boolean;
  dryRun: boolean;
  blockHeight: number;
}

export const description = "PriceReset can push uAD price lower or higher by burning LP token for uAD or 3CRV from the bonding contract";
export const params = {
  amount: "The amount of uAD-3CRV LP token to be withdrawn",
};
export const optionalParam = {
  pushHigher: ["if false will withdraw 3CRV to push uAD price lower", true, types.boolean],
  dryRun: ["if false will use account 0 to execute price reset", true, types.boolean],
  blockHeight: ["block height for the fork", 13135453, types.int],
};
export const action = priceResetter;
