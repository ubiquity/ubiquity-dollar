import dotenv from "dotenv"
import fs from "fs"
import path from "path"
import { TEST_MNEMONIC } from "../constants"

export type Env = {
    rpcUrl: string,
    privateKey: string,
    etherscanApiKey?: string,
}

export const getEnv = (): Env => {
    const envPath = path.join(__dirname, "../../../.env");
    if (!fs.existsSync(envPath)) {
        throw new Error("Env file not found")
    }

    dotenv.config({ path: envPath });
    const rpcUrl = process.env.RPC_URL || "http://localhost:8545";
    const privateKey = process.env.PRIVATE_KEY || TEST_MNEMONIC
    const etherscanApiKey = process.env.ETHERSCAN_API_KEY

    return {
        rpcUrl,
        privateKey,
        etherscanApiKey
    }
}