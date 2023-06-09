import { execSync } from "child_process";
import axios from "axios";
import fs from "fs";
import path from "path";

const executeCommand = (command) => {
  try {
    const output = execSync(command);
    return output.toString().trim();
  } catch (error) {
    console.error(`Error executing command: ${command}`);
    console.error(error.message);
    process.exit(1);
  }
};

const targetFolder = "../packages/contracts";

if (fs.existsSync(targetFolder)) {
  process.chdir(targetFolder);
} else {
  console.error("Target folder does not exist.");
}
// Get Diamond storage value before creating the pull request
const beforeValue = executeCommand("forge inspect Diamond storage");

// Check if a pull request exists
let prNumber = null;
const githubEventPath = process.env.GITHUB_EVENT_PATH;
console.log(githubEventPath);
if (githubEventPath) {
  const eventData = JSON.parse(fs.readFileSync(githubEventPath, "utf8"));
  console.log(eventData);
  prNumber = eventData.pull_request?.number || null;
}

if (prNumber) {
  // Get Diamond storage value after creating the pull request
  const afterValue = executeCommand("forge inspect Diamond storage");

  if (beforeValue === afterValue) {
    console.log("Diamond storage values are the same.");
  } else {
    console.log("Diamond storage values are different.");
  }
} else {
  // Pull request does not exist
  console.log("No pull request has been created yet.");
}
