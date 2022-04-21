import { FC } from "react";
import { WalletNotConnected } from "@/ui";
import { useConnectedContext } from "@/lib/connected";
import BondingSharesExplorer from "@/components/liquidity-mining/BondingSharesExplorer";

const LiquidityMining: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return account ? <BondingSharesExplorer /> : WalletNotConnected;
};

export default LiquidityMining;
