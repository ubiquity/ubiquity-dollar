import dotenv from "dotenv";
import { TEST_MNEMONIC } from "../constants";
import { Wallet } from "ethers";
import { warn } from "./logging";

function warnIfNotSet(key: string) {
  if (!process.env[key]?.length) {
    warn(`process.env.${key} not set`);
  } else {
    return process.env[key];
  }
}

export const loadEnv = (path: string) => {
  dotenv.config({ path });

  const rpcUrl = warnIfNotSet("RPC_URL") || "https://eth.ubq.fi/v1/mainnet";
  const privateKey = warnIfNotSet("PRIVATE_KEY") || Wallet.fromMnemonic(TEST_MNEMONIC).privateKey;
  const adminAddress = warnIfNotSet("PUBLIC_KEY") || Wallet.fromMnemonic(TEST_MNEMONIC).address;
  const curveWhale = warnIfNotSet("CURVE_WHALE") || "0x4486083589A063ddEF47EE2E4467B5236C508fDe";
  const _3CRV = warnIfNotSet("USD3CRV_TOKEN") || "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490";
  const mnemonic = warnIfNotSet("MNEMONIC") || "test test test test test test test test test test test junk";

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
