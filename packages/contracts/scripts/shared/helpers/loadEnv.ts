import dotenv from "dotenv";
import { CURVE_WHALE, FALLBACK_RPC, TEST_MNEMONIC, USD3CRV_TOKEN } from "../constants";
import { Wallet } from "ethers";
import { warn } from "./logging";

const warnIfNotSet = (key: string) => {
  if (!process.env[key]?.length) {
    warn(`process.env.${key} not set`);
    return false;
  } else {
    return process.env[key];
  }
};

export const loadEnv = (path: string) => {
  dotenv.config({ path });
  const rpcUrl = warnIfNotSet("RPC_URL") || FALLBACK_RPC;
  const privateKey = warnIfNotSet("PRIVATE_KEY") || Wallet.fromMnemonic(TEST_MNEMONIC).privateKey;
  const adminAddress = warnIfNotSet("PUBLIC_KEY") || Wallet.fromMnemonic(TEST_MNEMONIC).address;
  const curveWhale = warnIfNotSet("CURVE_WHALE") || CURVE_WHALE;
  const _3CRV = warnIfNotSet("USD3CRV_TOKEN") || USD3CRV_TOKEN;
  const mnemonic = warnIfNotSet("MNEMONIC") || TEST_MNEMONIC;

  const etherscanApiKey = warnIfNotSet("ETHERSCAN_API_KEY"); // no fallback

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
