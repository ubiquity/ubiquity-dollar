import { spawn } from "child_process";
import { RETRY_COUNT, RETRY_DELAY } from "./conf";

let shouldSkip = false;
let retryCount = 0;
const procFork = async () => {
  console.log(`using default anvil for unit-testing...`);
  const command = spawn("forge", ["test"]);
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

  command.on("close", async (code: number) => {
    console.log(`command closing on process`);
    // if linux command exit code is not success (0) then throw an error
    if (code !== 0) {
      throw new Error(`Failing tests ${code}`);
    } else {
      process.exit(0);
    }
  });
};

procFork();
