import { execSync } from "child_process";
import axios from "axios";
import fs from "fs";
import _ from "lodash";
import path from "path";

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

let fileNames = []; // Variable to store the file names

function getFileNamesFromFolder(folderPath) {
  return new Promise((resolve, reject) => {
    fs.readdir(folderPath, (err, files) => {
      if (err) {
        reject(err);
        return;
      }

      fileNames = files.map((file) => file.split(".")[0]);
      resolve(fileNames);
    });
  });
}

getFileNamesFromFolder(facetsFolder)
  .then(() => {
    const branchName = executeCommand("git rev-parse --abbrev-ref HEAD").replace(/[\n\r\s]+$/, "");
    let prStorageOutput = "";
    let devStorageOutput = "";

    console.log("BRANCH NAME: " + branchName);

    // trebuie sa le adaug in arrays pentru ca nu se salveaza valoarea si nu am cum sa compar
    for (let i = 0; i < fileNames.length; i++) {
      const fileName = fileNames[i];
 
      const storageOutput = executeCommand("forge inspect " + fileName + " storage");

      if (branchName === "development") {
        devStorageOutput += storageOutput;
      } else {
        prStorageOutput += storageOutput;
      }
    }
    console.log("DEV: " + devStorageOutput);
    console.log("PR: " + prStorageOutput);
    const ls = executeCommand("ls");
    console.log("LS: " + ls);
  })
  .catch((err) => {
    console.error("Error:", err);
  });

// console.log("Waiting for storage output...");
//
// // Check if a pull request exists
// const githubEventPath = process.env.GITHUB_EVENT_PATH;
// let prNumber = null;
//
// if (githubEventPath) {
//   const eventData = JSON.parse(fs.readFileSync(githubEventPath, "utf8"));
//   prNumber = eventData.pull_request?.number || null;
// }
//
// if (prNumber) {
//   // Get Diamond storage value after creating the pull request
//   const afterValue = executeCommand("forge inspect ChefFacet storage");
//
//   if (beforeValue === afterValue) {
//     console.log("Diamond storage values are the same.");
//   } else {
//     console.log("Diamond storage values are different.");
//   }
// } else {
//   console.log("No pull request has been created yet.");
// }
