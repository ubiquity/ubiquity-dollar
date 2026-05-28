export type UbiquityConfig = {
  walletConnectProjectId: string;
};

const ubqConfig = {
  // This is ours WalletConnect's default project ID.
  walletConnectProjectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || "ef004b660177d5660241cdb882fcbf84",
} as const satisfies UbiquityConfig;

export default ubqConfig;
