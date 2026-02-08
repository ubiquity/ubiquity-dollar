import { promises as fs } from "fs";

const filePath = process.argv[2];

async function main() {
  const sourceCode = await fs.readFile(filePath, "utf-8");
  const transformedCode = transformImportPaths(sourceCode);
  console.log(transformedCode);
}

function transformImportPaths(sourceCode: string): string {
  const importPattern = /(@ubiquity\/contracts\/out\/)([^/]+)(\.sol\/[^/]+\.json)/g;
  return sourceCode.replace(importPattern, (match, p1, p2, p3) => {
    const solFilename = p2;
    const transformedSolFilename = toKebabCase(solFilename);
    return `${p1}${transformedSolFilename}${p3}`;
  });
}

function toKebabCase(str: string): string {
  return str.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
