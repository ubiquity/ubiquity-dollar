import { spawnSync } from "child_process";
import { ethers } from "ethers";
import fs from "fs";
import path from "path";
import { loadEnv, warn } from "../../shared";
import { TEST_MNEMONIC } from "../../shared/constants/mnemonic";

const envPath = path.join(__dirname, "../../../.env");

if (!fs.existsSync(envPath)) {
  throw new Error("Env file not found");
}

(async function main() {
  const env = loadEnv(envPath);
  const { _3CRV, curveWhale } = env;

  // get the wallets from the TEST_MNEMONIC
  const wallet = ethers.Wallet.fromMnemonic(TEST_MNEMONIC);
  const adminAddress = wallet.address;

  console.log({ _3CRV, curveWhale, adminAddress });

  await impersonateAccount(curveWhale);
  await sendTokens(_3CRV, adminAddress, curveWhale);
  await stopImpersonatingAccount(curveWhale);
  await forgeScript();
})();

//

async function impersonateAccount(curveWhale: string) {
  warn("Impersonating 'CURVE_WHALE' account");

  spawnSync("cast", ["rpc", "anvil_impersonateAccount", curveWhale, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
}

async function sendTokens(_3CRV: string, adminAddress: string, curveWhale: string) {
  warn("Sending 10,000 3CRV LP tokens to 'PUBLIC_KEY'");

  spawnSync("cast", ["send", _3CRV, "transfer(address, uint256)", adminAddress, "10000000000000000000000", "--from", curveWhale], {
    stdio: "inherit",
  });
}

async function stopImpersonatingAccount(curveWhale: string) {
  warn("Ending account impersonation");

  spawnSync("cast", ["rpc", "anvil_stopImpersonatingAccount", curveWhale, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
}

async function forgeScript() {
  warn("Running Solidity script");

  spawnSync(
    "forge",
    ["script", "scripts/deploy/dollar/solidityScripting/08_DevelopmentDeploy.s.sol:DevelopmentDeploy", "--fork-url", "http://localhost:8545", "--broadcast"],
    {
      stdio: "inherit",
    }
  );
}
