import { spawnSync } from "child_process";
import { ethers } from "ethers";
import fs from "fs";
import path from "path";
import { loadEnv } from "../../shared";
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

  await impersonateAccount(curveWhale);
  await sendTokens(_3CRV, adminAddress, curveWhale);
  await stopImpersonatingAccount(curveWhale);
  await forgeScript();
})();

//

async function impersonateAccount(curveWhale) {
  console.log("----------------------------------------------------------------");
  console.log("Impersonating 'CURVE_WHALE' account");
  console.log("----------------------------------------------------------------");
  spawnSync("cast", ["rpc", "anvil_impersonateAccount", curveWhale, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
}

async function sendTokens(_3CRV, adminAddress, curveWhale) {
  console.log("----------------------------------------------------------------");
  console.log("Sending 10,000 3CRV LP tokens to 'PUBLIC_KEY'");
  console.log("----------------------------------------------------------------");
  spawnSync("cast", ["send", _3CRV, "transfer(address, uint256)", adminAddress, "10000000000000000000000", "--from", curveWhale], {
    stdio: "inherit",
  });
}

async function stopImpersonatingAccount(curveWhale) {
  console.log("----------------------------------------------------------------");
  console.log("Ending account impersonation");
  console.log("----------------------------------------------------------------");
  spawnSync("cast", ["rpc", "anvil_stopImpersonatingAccount", curveWhale, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
}

async function forgeScript() {
  console.log("----------------------------------------------------------------");
  console.log("Running Solidity script");
  console.log("----------------------------------------------------------------");
  spawnSync(
    "forge",
    ["script", "scripts/deploy/dollar/solidityScripting/08_DevelopmentDeploy.s.sol:DevelopmentDeploy", "--fork-url", "http://localhost:8545", "--broadcast"],
    {
      stdio: "inherit",
    }
  );
}
