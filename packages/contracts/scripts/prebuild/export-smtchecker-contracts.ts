import fs from "fs";
import path from "path";

const foundry_file = path.join(__dirname, "../../foundry.toml");

const getAllFiles = function (dirPath: string, arrayOfFiles: string[]) {
  const fullPath = path.join(__dirname, dirPath);
  const files = fs.readdirSync(fullPath);

  arrayOfFiles = arrayOfFiles || [];

  files.forEach(function (file) {
    if (fs.statSync(fullPath + "/" + file).isDirectory()) {
      arrayOfFiles = getAllFiles(dirPath + "/" + file, arrayOfFiles);
    } else {
      arrayOfFiles.push(path.join(dirPath, "/", file));
    }
  });

  return arrayOfFiles;
};

const main = () => {
  const buffer = fs.readFileSync(foundry_file);
  const fileContent = buffer.toString();
  let contracts = getAllFiles("../../src", []);
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

  const newContent = fileContent.replace(
    /\[profile\.default\.model_checker\.contracts\](.*?)(?:(?:\r*\n){2})/s,
    `[profile.default.model_checker.contracts]\n${contractsString}\n`
  );
  fs.writeFileSync(foundry_file, newContent);
};

main();
