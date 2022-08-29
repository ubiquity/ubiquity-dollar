import path from "path";
import { taskMounter } from "./utils/task-mounter";
import * as fs from "fs";

/**
 * This is an adapter to automatically import tasks from the library directory
 *  and map them to Hardhat by taking the filename and using that for the task name.
 *  all of the rest (description, parameters etc) are defined within each task file
 */

export const libraryDirectory = path.join(__dirname, "library");

// auto import tasks in library
fs.readdirSync(libraryDirectory) // read library directory
  .filter((filename) => filename.endsWith(".ts")) // only typescript files
  .forEach(taskMounter); // process each file
