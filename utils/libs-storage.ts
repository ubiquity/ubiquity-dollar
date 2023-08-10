const fs = require('fs');
const path = require('path');
import { execSync } from "child_process";

const libsFolder = "../packages/contracts/src/dollar/libraries";

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

fs.readdir(libsFolder, (err, files) => {
  if (err) {
    console.error('Error reading the directory:', err);
    return;
  }

  const fileNames = files.filter((file) => fs.statSync(path.join(libsFolder, file)).isFile());

  fileNames.forEach((fileName) => {
    const filePath = path.join(libsFolder, fileName);
    fs.readFile(filePath, 'utf8', (err, data) => {
      if (err) {
        console.error('Error reading the file:', err);
        return;
      }

      const dataArray = data.split('\n');

      const structBlocks = [];
      let insideStruct = false;
      let currentStruct = '';

      for (const line of dataArray) {
        // Remove comments starting with "//" until the end of the line
        const lineWithoutComments = line.replace(/\/\/.*$/, '').trim();

        // Check if the line starts with "struct "
        if (lineWithoutComments.startsWith('struct ')) {
          insideStruct = true;
          currentStruct = lineWithoutComments;
        } else if (insideStruct) {
          if (lineWithoutComments === '}') {
            // Check if the line ends with "}"
            insideStruct = false;
            currentStruct += ' ' + lineWithoutComments;
            structBlocks.push(currentStruct);
          } else {
            currentStruct += ' ' + lineWithoutComments;
          }
        }
      }

      const branchName = executeCommand("git rev-parse --abbrev-ref HEAD").replace(/[\n\r\s]+$/, "");

      if (branchName === "development") {
        fs.writeFileSync("dev_libs_storage_output.txt", structBlocks.toString());
      } else {
        fs.writeFileSync("pr_libs_storage_output.txt", structBlocks.toString());
      }
      console.log(structBlocks.toString());
    });
  });
});
