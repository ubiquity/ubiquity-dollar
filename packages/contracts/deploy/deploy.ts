import fs from "fs"
import path from "path"
import { DEPLOY_FUNCS } from "./manager";
import { loadEnv } from "./utils";

const main = async () => {
    const cmdArgs = process.argv.slice(2);
    const name = cmdArgs[0];
    if (!name) {
        throw new Error("You MUST put the script name in command arguments at least")
    }

    const envPath = path.join(__dirname, "../.env");
    if (!fs.existsSync(envPath)) {
        throw new Error("Env file not found")
    }
    const env = loadEnv(envPath);

    if (!DEPLOY_FUNCS[name]) {
        throw new Error(`Did you create a script for ${name} or maybe you forgot to configure it?`);
    }

    const deployHandler = DEPLOY_FUNCS[name];
    const result = await deployHandler({ env, args: cmdArgs })
    console.log(`Deployed ${name} contract successfully. res: ${result}`);

}

main()