import { FC } from "react";
import { useConnectedContext } from "../components/context/connected";
import BondingSharesExplorer from "../components/BondingSharesExplorer";
import { WalletNotConnected } from "../components/ui/widget";

const LiquidityMining: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return account ? <BondingSharesExplorer /> : WalletNotConnected;
};

export default LiquidityMining;
