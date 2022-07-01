import { FC } from "react";
import { WalletNotConnected } from "@/ui";
import StakingSharesExplorer from "@/components/staking/StakingSharesExplorer";
import { useWalletAddress } from "@/components/lib/hooks";

const Staking: FC = (): JSX.Element => {
  const [walletAddress] = useWalletAddress();
  return walletAddress ? <StakingSharesExplorer /> : WalletNotConnected;
};

export default Staking;
