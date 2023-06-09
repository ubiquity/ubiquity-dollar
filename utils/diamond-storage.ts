import { execSync } from "child_process";
import axios from "axios";
import fs from "fs";

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

// Get Diamond storage value before creating the pull request
executeCommand("cd packages/contracts");
const beforeValue = executeCommand("forge inspect Diamond storage");

// Check if a pull request exists
let prNumber = null;
const githubEventPath = process.env.GITHUB_EVENT_PATH;
if (githubEventPath) {
  const eventData = JSON.parse(fs.readFileSync(githubEventPath, "utf8"));
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

  console.log("Before value:", beforeValue);
  console.log("After value:", afterValue);
} else {
  // Pull request does not exist
  console.log("No pull request has been created yet.");
}
