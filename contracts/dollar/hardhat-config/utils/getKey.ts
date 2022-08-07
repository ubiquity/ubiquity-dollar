import { warn } from "./warn";


export function getKey(keyName: "ETHERSCAN" | "COINMARKETCAP") {
    const PREFIX = "API_KEY_";
    const ENV_KEY = PREFIX.concat(keyName);
    if (process.env[ENV_KEY]) {
        return process.env[ENV_KEY] as string;
    } else {
        warn(`Please set the ${ENV_KEY} environment variable to your ${keyName} API key`);
    }
}
