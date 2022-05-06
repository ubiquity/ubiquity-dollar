import { FC } from "react";
import { WalletNotConnected } from "@/ui";
import BondingSharesExplorer from "@/components/liquidity-mining/BondingSharesExplorer";
import { useWalletAddress } from "@/components/lib/hooks";

const LiquidityMining: FC = (): JSX.Element => {
  const [walletAddress] = useWalletAddress();
  return walletAddress ? <BondingSharesExplorer /> : WalletNotConnected;
};

export default LiquidityMining;
