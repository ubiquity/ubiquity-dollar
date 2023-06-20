import fs from "fs";
import path from "path";
import _ from "lodash";

function walk(dir: string, done: (err: Error | null, results?: string[]) => void) {
  let results: string[] = [];
  fs.readdir(dir, function (err, list) {
    if (err) return done(err);
    list = list.filter((item) => !/(^|\/)\.[^/.]/g.test(item)); // Ignore hidden files/directories
    let pending = list.length;
    if (!pending) return done(null, results);
    list.forEach(function (file) {
      file = path.resolve(dir, file);
      fs.stat(file, function (err, stat) {
        if (stat && stat.isDirectory()) {
          walk(file, function (err, res) {
            results = results.concat(res!);
            if (!--pending) done(null, results);
          });
        } else {
          results.push(file);
          if (!--pending) done(null, results);
        }
      });
    });
  });
}

function renameAndReplaceFilesInDir(dir: string) {
  walk(dir, function (err, files) {
    if (err) throw err;

    // Store old and new file paths
    const filePaths: { old: string; new: string }[] = [];

    files!.forEach(function (file) {
      const oldName = path.basename(file);
      const newNameWithoutExtension = _.kebabCase(path.parse(oldName).name);
      const extension = path.parse(oldName).ext;
      const newName = `${newNameWithoutExtension}${extension}`;
      const newPath = path.join(path.dirname(file), newName);

      // Rename file
      fs.renameSync(file, newPath);

      // Store old and new file paths
      filePaths.push({ old: file, new: newPath });
    });

    // Replace all references of oldName without extension with newName without extension in all .ts and .tsx files
    filePaths.forEach(({ old, new: newPath }) => {
      const oldName = path.basename(old);
      const oldNameWithoutExtension = path.parse(oldName).name;
      const newNameWithoutExtension = _.kebabCase(oldNameWithoutExtension);

      filePaths.forEach((filePath) => {
        if (filePath.new.endsWith(".ts") || filePath.new.endsWith(".tsx")) {
          const data = fs.readFileSync(filePath.new, "utf-8");
          // Match only occurrences of oldNameWithoutExtension within quotes
          const regex = new RegExp(`(['"\`])${oldNameWithoutExtension}(['"\`])`, "g");
          const result = data.replace(regex, `$1${newNameWithoutExtension}$2`);
          fs.writeFileSync(filePath.new, result, "utf-8");
        }
      });
    });
  });
}

// Usage
renameAndReplaceFilesInDir("./packages");
