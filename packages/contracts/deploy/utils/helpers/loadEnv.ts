import dotenv from "dotenv"
import { TEST_MNEMONIC } from "../constants"

export const loadEnv = (path: string): Env => {
    dotenv.config({ path });
    const rpcUrl = process.env.RPC_URL || "http://localhost:8545";
    const privateKey = process.env.PRIVATE_KEY || TEST_MNEMONIC
    const etherscanApiKey = process.env.ETHERSCAN_API_KEY

    return {
        rpcUrl,
        privateKey,
        etherscanApiKey
    }
}