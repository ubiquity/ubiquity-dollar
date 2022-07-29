import { FC } from "react";
import { WalletNotConnected } from "@/ui";
import BondingSharesExplorer from "@/components/staking/StakingSharesExplorer";
import { useWalletAddress } from "@/components/lib/hooks";

const Staking: FC = (): JSX.Element => {
  const [walletAddress] = useWalletAddress();
  return walletAddress ? <BondingSharesExplorer /> : WalletNotConnected;
};

export default Staking;
