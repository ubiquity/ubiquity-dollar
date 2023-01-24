import { spawn } from "child_process";
import { loadEnv } from "../../shared";
import fs from "fs";
import path from "path";

const envPath = path.join(__dirname, "../../../.env");
if (!fs.existsSync(envPath)) {
  throw new Error("Env file not found");
}
const env = loadEnv(envPath);

const whaleAccount = env.curveWhale;
const adminAddress = env.adminAddress;

const impersonateAccount = async () => {
  spawn("cast", ["rpc", "anvil_impersonateAccount", whaleAccount, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
  console.log("Impersonating 'CURVE_WHALE' account");
};

const sendTokens = async () => {
  spawn(
    "cast",
    [
      "send",
      adminAddress,
      "0xa9059cbb000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb9226600000000000000000000000000000000000000000000021e19e0c9bab2400000",
      "--from",
      whaleAccount,
    ],
    {
      stdio: "inherit",
    }
  );
  console.log("Sent 10000 3CRV LP tokens to 'ADMIN_ADDRESS'");
};

const stopImpersonatingAccount = async () => {
  spawn("cast", ["rpc", "anvil_stopImpersonatingAccount", whaleAccount, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
  console.log("Ending account impersonation");
};

const forgeScript = async () => {
  console.log("Running Solidity script");
  spawn(
    "forge",
    ["script", "scripts/deploy/dollar/solidityScripting/08_DevelopmentDeploy.s.sol:DevelopmentDeploy", "--fork-url", "http://localhost:8545", "--broadcast"],
    {
      stdio: "inherit",
    }
  );
};

const main = async () => {
  await impersonateAccount();
  await sendTokens();
  await stopImpersonatingAccount();
  await forgeScript();
};

main();
