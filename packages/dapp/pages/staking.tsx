import { FC } from "react";
import BondingSharesExplorer from "@/components/staking/BondingSharesExplorer";
import useWalletAddress from "@/components/lib/hooks/useWalletAddress";
import WalletNotConnected from "@/components/ui/WalletNotConnected";

const Staking: FC = (): JSX.Element => {
  const [walletAddress] = useWalletAddress();
  return walletAddress ? <BondingSharesExplorer /> : WalletNotConnected;
};

export default Staking;
