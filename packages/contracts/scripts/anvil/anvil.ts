import axios from "axios";
import { spawn } from "child_process";
import { loadEnv } from "../../shared";
import fs from "fs";
import path from "path";

const getUrl = async () => {
  const envPath = path.join(__dirname, "../../../.env");
  if (!fs.existsSync(envPath)) {
    throw new Error("Env file not found");
  }
  const env = loadEnv(envPath);

  return env.rpcUrl;
};

(async () => {
  const currentRPC = await getUrl();
  console.log(`using ${currentRPC} for anvil...`);
  const command = spawn("anvil", ["-f", currentRPC as string, "-m", "test test test test test test test test test test test junk", "--chain-id", "31337"]);
  command.stdout.on("data", (output: any) => {
    console.log(output.toString());
  });
})();
