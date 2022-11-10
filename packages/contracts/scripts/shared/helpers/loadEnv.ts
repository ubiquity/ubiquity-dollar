import dotenv from "dotenv"
import { TEST_MNEMONIC } from "../constants"
import { Env } from "../types";
import { Wallet } from "ethers"

export const loadEnv = (path: string): Env => {
    dotenv.config({ path });
    const owner = process.env.OWNER || "0x9F79941335e54A11eCD13cedf58375657FdA97A1";
    const rpcUrl = process.env.RPC_URL || "http://localhost:8545";
    const privateKey = process.env.PRIVATE_KEY || Wallet.fromMnemonic(TEST_MNEMONIC).privateKey;
    const etherscanApiKey = process.env.ETHERSCAN_API_KEY

    return {
        owner,
        rpcUrl,
        privateKey,
        etherscanApiKey
    }
}