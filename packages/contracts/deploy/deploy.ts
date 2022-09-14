import fs from "fs"
import path from "path"
import { create } from "./create";
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

    // TODO: Both things should be done here
    // 1. Gets the contract relative path from the name
    // 2. Should parse args to get a list of individual argument
    const contractInstance = name;
    const constructorArguments = [args];
    const { stdout, stderr } = await create({ ...env, contractInstance, constructorArguments })
    console.log(`Deployed ${name} contract successfully, stdout: ${stdout}, stderr: ${stderr}`);

}

export default func;