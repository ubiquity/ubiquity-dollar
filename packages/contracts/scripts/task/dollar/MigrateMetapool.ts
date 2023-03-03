import { spawnSync } from "child_process";
import { loadEnv } from "../../shared";
import fs from "fs";
import path from "path";

const envPath = path.join(__dirname, "../../../.env");
if (!fs.existsSync(envPath)) {
  throw new Error("Env file not found");
}
const env = loadEnv(envPath);

const rpcUrl = env.rpcUrl as string;

const migrateMetapool = async () => {
  console.log("Running Solidity Script to Migrate Metapool Funds");
  spawnSync("forge", ["script", "scripts/dollar/MigrateMetapool.s.sol", "--fork-url", rpcUrl, "--broadcast"]);
};

migrateMetapool();
