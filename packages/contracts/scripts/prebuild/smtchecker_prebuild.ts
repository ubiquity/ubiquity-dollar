import fs from "fs";
import path from "path";

const foundry_file = path.join(__dirname, "../../foundry.toml");

export const getAllFiles = (dirPath: string): string[] => {
  const fullPath = path.join(__dirname, dirPath);

  const files = fs.readdirSync(fullPath);
  let arrayOfFiles: string[] = [];

  files.forEach((file) => {
    const filePath = path.join(fullPath, file);
    const fileStat = fs.statSync(filePath);

    if (fileStat.isDirectory()) {
      const nestedFiles = getAllFiles(path.join(dirPath, file));
      arrayOfFiles = arrayOfFiles.concat(nestedFiles);
    } else {
      arrayOfFiles.push(path.join(dirPath, file));
    }
  });

  console.log(arrayOfFiles);
  return arrayOfFiles;
};

const updateFoundryFile = () => {
  const buffer = fs.readFileSync(foundry_file);
  const fileContent = buffer.toString();
  let contracts = getAllFiles("../../src");
  contracts = contracts.map((contract: string) => contract.replace("../../", ""));

  let contractsString = "";
  contracts.forEach((contract: string) => {
    const contractContent = fs.readFileSync(path.join(__dirname, "../../", contract)).toString();
    const namesMatched = contractContent.match(/contract\s+(\w+)\s+(is|{)/g);
    if (namesMatched) {
      const names = namesMatched.map((name: string) => name.replace("contract", "").replace(/{/g, "").replace("is", "").trim());
      contractsString += `'${contract}' = [ '${names.join(", ")}' ]\n`;
    }
  });

  /// Problem is from here
  const newContent = fileContent.replace(
    /\[profile\.default\.model_checker\.contracts\](.*?)(?:(?:\r*\n){2})/s,
    `[profile.default.model_checker.contracts]\n${contractsString}\n`
  );
  console.log(contractsString);
  fs.writeFileSync(foundry_file, newContent);
  console.log(foundry_file);
};

updateFoundryFile();
