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
    files!.forEach(function (file) {
      const oldName = path.basename(file);
      const newNameWithoutExtension = _.kebabCase(path.parse(oldName).name);
      const extension = path.parse(oldName).ext;
      const newName = `${newNameWithoutExtension}${extension}`;
      const newPath = path.join(path.dirname(file), newName);

      // Rename file
      fs.renameSync(file, newPath);

      // Replace all references of oldName with newName in all .ts and .tsx files
      files!.forEach((filePath) => {
        if (filePath.endsWith(".ts") || filePath.endsWith(".tsx")) {
          try {
            const data = fs.readFileSync(filePath, "utf-8");
            const regex = new RegExp(oldName, "g");
            const result = data.replace(regex, newName);
            fs.writeFileSync(filePath, result, "utf-8");
          } catch (error) {
            console.error(error);
          }
        }
      });
    });
  });
}

// Usage
renameAndReplaceFilesInDir("./packages");
