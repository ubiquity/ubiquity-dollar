import fs from "fs";
import path from "path";

const foundry_file = path.join(__dirname, "../../foundry.toml");

function getAllFiles(dirPath: string, arrayOfFiles: string[]): string[] {
  const fullPath = path.resolve(dirPath);
  const files = fs.readdirSync(fullPath);

  for (const file of files) {
    const filePath = path.join(fullPath, file);
    const fileStat = fs.statSync(filePath);

    if (fileStat.isDirectory()) {
      getAllFiles(filePath, arrayOfFiles);
    } else {
      arrayOfFiles.push(filePath);
    }
  }

  return arrayOfFiles;
}

function updateFoundryFile() {
  const fileContent = fs.readFileSync(foundry_file, "utf8");
  const contracts = getAllFiles("../../src", []).map((contract) =>
    contract.replace("../../", "")
  );

  let contractsString = "";
  for (const contract of contracts) {
    const contractContent = fs.readFileSync(
      path.join(__dirname, "../../", contract),
      "utf8"
    );
    const namesMatched = contractContent.match(/contract\s+(\w+)\s+(is|{)/g);
    if (namesMatched) {
      const names = namesMatched.map((name) =>
        name.replace(/contract|{|is/g, "").trim()
      );
      contractsString += `'${contract}' = [ '${names.join(", ")}' ]\n`;
    }
  }

  const newContent = fileContent.replace(
    /\[profile\.default\.model_checker\.contracts\](.*?)(?:(?:\r*\n){2})/s,
    `[profile.default.model_checker.contracts]\n${contractsString}\n`
  );
  fs.writeFileSync(foundry_file, newContent, "utf8");
}

updateFoundryFile();
