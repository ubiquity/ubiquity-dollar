import dotenv from "dotenv";
import { TEST_MNEMONIC } from "../constants";
import { Env } from "../types";
import { Wallet } from "ethers";

export const loadEnv = (path: string): Env => {
  dotenv.config({ path });
  const rpcUrl = process.env.RPC_URL || "http://localhost:8545";
  const privateKey = process.env.PRIVATE_KEY || Wallet.fromMnemonic(TEST_MNEMONIC).privateKey;
  const adminAddress = process.env.PUBLIC_KEY || Wallet.fromMnemonic(TEST_MNEMONIC).address;
  const etherscanApiKey = process.env.ETHERSCAN_API_KEY;
  const curveWhale = process.env.CURVE_WHALE || "0x4486083589A063ddEF47EE2E4467B5236C508fDe";
  const _3CRV = process.env.USD3CRV_TOKEN || "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490";
  const mnemonic = process.env.MNEMONIC || "test test test test test test test test test test test junk";

  return {
    rpcUrl,
    privateKey,
    adminAddress,
    etherscanApiKey,
    curveWhale,
    _3CRV,
    mnemonic,
  };
};
