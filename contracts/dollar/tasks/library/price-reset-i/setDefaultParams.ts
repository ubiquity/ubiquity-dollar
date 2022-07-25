import { TaskArgs } from "../price-reset-i";
export function setDefaultParams(taskArgs: TaskArgs) {
  if (!taskArgs["pushHigher"]) {
    taskArgs["pushHigher"] = true;
  }
  if (!taskArgs["dryRun"]) {
    taskArgs["dryRun"] = true;
  }
  if (!taskArgs["blockHeight"]) {
    taskArgs["blockHeight"] = 13135453;
  }
}
