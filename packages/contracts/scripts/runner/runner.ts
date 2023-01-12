import { spawn } from "child_process";
import { LOCAL_RPC, RETRY_COUNT, RETRY_DELAY } from "./conf";

let shouldSkip = false;
let retryCount = 0;
const procFork = async () => {
  const optimalRPC = LOCAL_RPC;
  const anvil = spawn("anvil");
  console.log(`using ${optimalRPC} for unit-testing...`);
  const command = spawn("forge", ["test", "--fork-url", optimalRPC as string]);
  shouldSkip = false;
  command.stdout.on("data", (output: unknown) => {
    console.log(output?.toString());
  });
  command.stderr.on("data", (output: unknown) => {
    console.log(output?.toString());
    if (shouldSkip === false && retryCount <= RETRY_COUNT) {
      retryCount++;
      setTimeout(() => {
        procFork();
      }, RETRY_DELAY);
      shouldSkip = true;
    }
  });
  command.on("close", (code: number) => {
    anvil.kill("SIGINT");
    // if linux command exit code is not success (0) then throw an error
    if (code !== 0) {
      throw new Error(`Failing tests ${code}`);
    }
    process.exit();
  });
};

procFork();
