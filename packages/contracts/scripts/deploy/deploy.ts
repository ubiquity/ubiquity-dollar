import { Deploy_Manager } from "./manager";
import CommandLineArgs from "command-line-args";
import { optionDefinitions } from "./definition";

const main = async () => {
  const cmdArgs = process.argv.slice(2);
  const name = cmdArgs[0];
  if (!name) {
    throw new Error("You MUST put the script name in command arguments at least");
  }

  if (!Deploy_Manager[name]) {
    throw new Error(`Did you create a script for ${name} or maybe you forgot to configure it?`);
  }

  let args;
  try {
    args = CommandLineArgs(optionDefinitions);
  } catch (error: unknown) {
    console.error(`Argument parse failed!, error: ${error}`);
    return;
  }

  const deployHandler = Deploy_Manager[name];
  const result = await deployHandler(args);
  console.log(`Deployed ${name} contract successfully. res: ${result}`);
};

main();
