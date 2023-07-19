const fs = require('fs');
const path = require('path');

const libsFolder = "../packages/contracts/src/dollar/libraries";

fs.readdir(libsFolder, (err, files) => {
  if (err) {
    console.error('Error reading the directory:', err);
    return;
  }

  // Filter out only files (excluding directories)
  const fileNames = files.filter((file) => fs.statSync(path.join(libsFolder, file)).isFile());

  // Process each file
  fileNames.forEach((fileName) => {
    const filePath = path.join(libsFolder, fileName);
    fs.readFile(filePath, 'utf8', (err, data) => {
      if (err) {
        console.error('Error reading the file:', err);
        return;
      }

      console.log(`Content of ${fileName}:`);

      // Split the data into an array of lines
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
          // If inside a struct block, add the line to currentStruct
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

      // Now you have an array with the content of each struct block
      console.log(structBlocks);
    });
  });
});
