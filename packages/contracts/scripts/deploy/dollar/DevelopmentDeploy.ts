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

(async () => {
  const command = spawn("cast", ["rpc", "anvil_impersonateAccount", whaleAccount, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
})();

(async () => {
  const command = spawn(
    "cast",
    [
      "send",
      "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490",
      "0xa9059cbb000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb9226600000000000000000000000000000000000000000000021e19e0c9bab2400000",
      "--from",
      whaleAccount,
    ],
    {
      stdio: "inherit",
    }
  );
})();

(async () => {
  const command = spawn("cast", ["rpc", "anvil_stopImpersonatingAccount", whaleAccount, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
})();

(async () => {
  const command = spawn(
    "forge",
    ["script", "scripts/deploy/dollar/solidityScripting/08_DevelopmentDeploy.s.sol:DevelopmentDeploy", "--fork-url", "http://localhost:8545", "--broadcast"],
    {
      stdio: "inherit",
    }
  );
})();
