import fs from "fs"
import path from "path"
import { loadEnv } from "./utils";

const func = async () => {
    const cmdArgs = process.argv.slice(2);
    const name = cmdArgs[1];
    const args = cmdArgs[2];

    const envPath = path.join(__dirname, "../.env");
    if (!fs.existsSync(envPath)) {
        throw new Error("Env file not found")
    }
    const env = loadEnv(envPath);

    // TODO: Gets the contract relative path from the name
    const contractInstance = name;

}

export default func;