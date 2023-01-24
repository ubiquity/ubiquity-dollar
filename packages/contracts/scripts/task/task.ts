import fs from "fs";
import path from "path";
import { TASK_FUNCS } from "./manager";
import { loadEnv } from "../shared";
import CommandLineArgs from "command-line-args";

const main = async () => {
  const cmdArgs = process.argv.slice(2);
  const name = cmdArgs[0];
  if (!name) {
    throw new Error("You MUST put the task name in command arguments at least");
  }

  const envPath = path.join(__dirname, "../.env");
  if (!fs.existsSync(envPath)) {
    throw new Error("Env file not found");
  }
  const env = loadEnv(envPath);

  if (!TASK_FUNCS[name]) {
    throw new Error(`Did you create a task for ${name} or maybe you forgot to configure it?`);
  }

  const taskHandler = TASK_FUNCS[name].handler;
  const commandLineParseOptions = TASK_FUNCS[name].options;
  let args;
  try {
    args = CommandLineArgs(commandLineParseOptions);
  } catch (error: any) {
    console.error(`Argument parse failed!, error: ${error}`);
    return;
  }

  const result = await taskHandler({ env, args });
  console.log(`Task ${name} run successfully. res: ${result}`);
};

main();
