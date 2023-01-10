import { exec } from "child_process";
import util from "util";
export const execute = util.promisify(exec);
