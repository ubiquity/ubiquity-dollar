export type UbiquityConfig = {
  walletConnectProjectId: string;
};

const ubqConfig = {
  // This is ours WalletConnect's default project ID.
  // It's recommended to store it in an env variable:
  // .env.local for local testing, and in the Vercel/system env config for live apps.
  walletConnectProjectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || "ef004b660177d5660241cdb882fcbf84",
} as const satisfies UbiquityConfig;

export default ubqConfig;
