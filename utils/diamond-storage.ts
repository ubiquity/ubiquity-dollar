import { execSync } from "child_process";
import axios from "axios";
import fs from "fs";
import path from "path";
import facetsHelper from "../packages/contracts/src/dollar/facets-helper";

const facetsFolder = "./src/dollar/facets";
const targetFolder = "../packages/contracts";

const executeCommand = (command) => {
  try {
    const output = execSync(command);
    return output.toString();
  } catch (error) {
    console.error(`Error executing command: ${command}`);
    console.error(error.message);
    process.exit(1);
  }
};

if (fs.existsSync(targetFolder)) {
  process.chdir(targetFolder);
} else {
  console.error("Target folder does not exist.");
}
// Get Diamond storage value before creating the pull request
const beforeValue = executeCommand("forge inspect ChefFacet storage");

let storageOutput = "";
const getStorageOutput = facetsHelper.getFacetsName(facetsFolder, (err, fileNames) => {
  if (err) {
    console.error("Error:", err);
    return;
  }

  for (let i = 0; i < fileNames.length; i++) {
    const fileName = fileNames[i];
    const storageCheck = executeCommand("forge inspect " + fileName + " storage");
    storageOutput += storageCheck;
  }
  return storageOutput;
});

console.log("getStorageOutput" + getStorageOutput);

// Check if a pull request exists
const githubEventPath = process.env.GITHUB_EVENT_PATH;
let prNumber = null;

const ls = executeCommand("ls");
console.log("LS: ", ls);

if (githubEventPath) {
  const eventData = JSON.parse(fs.readFileSync(githubEventPath, "utf8"));
  prNumber = eventData.pull_request?.number || null;
}

if (prNumber) {
  // Get Diamond storage value after creating the pull request
  const afterValue = executeCommand("forge inspect ChefFacet storage");

  if (beforeValue === afterValue) {
    console.log("Diamond storage values are the same.");
  } else {
    console.log("Diamond storage values are different.");
  }
} else {
  console.log("No pull request has been created yet.");
}
