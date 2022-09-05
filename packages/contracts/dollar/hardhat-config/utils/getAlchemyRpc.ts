import { warn } from "./warn";
export function getAlchemyRpc(network: "mainnet" | "ropsten" | "rinkeby"): string | undefined {
  // This will try and resolve alchemy key related issues
  // first it will read the key value
  // if no value found, then it will attempt to load the .env from above to the .env in the current folder
  // if that fails, then it will throw an error and allow the developer to rectify the issue
  if (process.env.API_KEY_ALCHEMY?.length) {
    return `https://eth-${network}.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY}`;
  } else {
    // we don't need to throw error here because there would be a couple of alternatives.
    warn("Please set the API_KEY_ALCHEMY environment variable to your Alchemy API key");
    return undefined;
  }
}
