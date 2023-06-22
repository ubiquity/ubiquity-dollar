import fs from "fs";

// A helper function to convert a string to kebab-case
function toKebabCase(str: string): string {
  return str.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
}

// The main function to transform the paths
function transformImportPaths(code: string): string {
  // Match import paths using a regex
  const importPathRegex = /import \{.*?\} from "(.*?)";/g;

  // Replace the paths with their kebab-case version
  return code.replace(importPathRegex, (match: string, importPath: string) => {
    // Split the path into segments
    const segments: string[] = importPath.split("/");

    // Transform each segment to kebab-case
    const transformedSegments: string[] = segments.map((segment) => toKebabCase(segment));

    // Join the segments back together
    const transformedPath: string = transformedSegments.join("/");

    // Replace the path in the import statement with the transformed path
    return match.replace(importPath, transformedPath);
  });
}

// pass in solidity code as the argument to the runtime from the command line
fs.readFile(process.argv[2], "utf8", (err, data) => {
  if (err) {
    console.error(err);
    return;
  }
  console.log(transformImportPaths(data));
});
