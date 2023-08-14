import { execSync } from "child_process";
import axios from "axios";
import fs from "fs";
import _ from "lodash";
import path from "path";

const facetsFolder = "./src/dollar/facets";
const libsFolder = "./src/dollar/libraries";
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

    let storageOutputString;

    for (let i = 0; i < fileNames.length; i++) {
      const fileName = fileNames[i];

      const storageOutput = executeCommand("forge inspect " + fileName + " storage --pretty");
      storageOutputString = JSON.stringify(storageOutput);

      if (branchName === "development") {
        devStorageOutput += storageOutputString;
      } else {
        prStorageOutput += storageOutputString;
      }
    }

    if (branchName === "development") {
      fs.writeFileSync("dev_storage_output.txt", devStorageOutput); 
    } else {
      fs.writeFileSync("pr_storage_output.txt", prStorageOutput);
    }
  })
  .catch((err) => {
    console.error("Error:", err);
  });

console.log("Waiting for storage output...");
