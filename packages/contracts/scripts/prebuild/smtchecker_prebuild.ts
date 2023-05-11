import fs from "fs";
import path from "path";

const foundry_file = path.join(__dirname, "../../foundry.toml");

function getAllFiles(dirPath: string, arrayOfFiles: string[]): string[] {
  const fullPath = path.resolve(dirPath);
  const files = fs.readdirSync(fullPath);

  arrayOfFiles = arrayOfFiles || [];

  files.forEach(function (file) {
    const filePath = path.join(fullPath, file);
    const fileStat = fs.statSync(filePath);

    if (fileStat.isDirectory()) {
      arrayOfFiles = getAllFiles(filePath, arrayOfFiles);
    } else {
      arrayOfFiles.push(filePath);
    }
  });

  return arrayOfFiles;
}
