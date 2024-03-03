/* eslint-disable @typescript-eslint/no-var-requires */
module.exports = {
  publicRuntimeConfig: {
    NEXT_PUBLIC_JSON_RPC_URL: process.env.NEXT_PUBLIC_JSON_RPC_URL,
    NEXT_PUBLIC_WALLET_CONNECT_ID: process.env.NEXT_PUBLIC_WALLET_CONNECT_ID,
  },
  env: {
    GIT_COMMIT_REF: require("child_process").execSync("git rev-parse --short HEAD").toString().trim(),
  },
};
