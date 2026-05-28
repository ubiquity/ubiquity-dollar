import { spawn } from "child_process";
import { loadEnv } from "../shared";
import { getRPC } from "../runner/rpcutil";
import fs from "fs";
import path from "path";

let optimalRPC;

const envPath = path.join(__dirname, "/../../.env");
if (!fs.existsSync(envPath)) {
  const envExamplePath = path.join(__dirname, "/../../.env.example");
  fs.copyFileSync(envExamplePath, envPath);
  console.log(".env file created from .env.example");
  console.log("check .env for changes when in need");
}

const env = loadEnv(envPath);

const getUrl = async () => {
  return env.rpcUrl;
};

const mnemonic = env.mnemonic;

(async () => {
  optimalRPC = await getUrl();
  if (optimalRPC == "http://localhost:8545") {
    optimalRPC = (await getRPC()).toString();
  }
  console.log(`using ${optimalRPC} for anvil...`);
  const command = spawn("anvil", ["-f", optimalRPC as string, "-m", mnemonic as string, "--chain-id", "31337"]);
  command.stdout.on("data", (output: any) => {
    console.log(output.toString());
  });
})();
