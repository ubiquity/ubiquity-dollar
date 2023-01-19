import { spawn } from "child_process";
import { RETRY_COUNT, RETRY_DELAY, TEST_PATTERN } from "./conf";
import { getRPC } from "./rpcutil";

let currentCode = 0;

let shouldRemoteSkip = false;
let retryRemoteCount = 0;
const procRemoteFork = async () => {
  const optimalRPC = await getRPC();
  console.log(`using ${optimalRPC} for unit-testing...`);
  const command = spawn("forge", ["test", "--fork-url", optimalRPC as string, "--match-contract", TEST_PATTERN]);
  shouldRemoteSkip = false;
  command.stdout.on("data", (output: unknown) => {
    console.log(output?.toString());
  });
  command.stderr.on("data", (output: unknown) => {
    console.log(output?.toString());
    if (shouldRemoteSkip === false && retryRemoteCount <= RETRY_COUNT) {
      retryRemoteCount++;
      setTimeout(() => {
        procRemoteFork();
      }, RETRY_DELAY);
      shouldRemoteSkip = true;
    }
  });
  command.on("close", (code: number) => {
    // if linux command exit code is not success (0) then throw an error
    if (currentCode !== 0 || code !== 0) {
      const failedOrigin = currentCode !== 0 && code !== 0 ? "Local and Remote" : currentCode !== 0 ? "Local" : "Remote";
      throw new Error(`Failing tests on ${failedOrigin} origin.`);
    } else {
      process.exit(0);
    }
  });
};

let shouldLocalSkip = false;
let retryLocalCount = 0;
const procLocalFork = async () => {
  console.log(`using default anvil for unit-testing...`);
  const command = spawn("forge", ["test", "--no-match-contract", TEST_PATTERN]);
  shouldLocalSkip = false;
  command.stdout.on("data", (output: unknown) => {
    console.log(output?.toString());
  });
  command.stderr.on("data", (output: unknown) => {
    console.log(output?.toString());
    if (shouldLocalSkip === false && retryLocalCount <= RETRY_COUNT) {
      retryLocalCount++;
      setTimeout(() => {
        procLocalFork();
      }, RETRY_DELAY);
      shouldLocalSkip = true;
    }
  });

  command.on("close", async (code: number) => {
    console.log(`command closing on local process`);
    currentCode = code;
    procRemoteFork();
  });
};

procLocalFork();
