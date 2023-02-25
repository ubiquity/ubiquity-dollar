import { FC } from "react";
import StakingSharesExplorer from "@/components/staking/StakingSharesExplorer";
import WalletConnectionWall from "@/components/ui/WalletConnectionWall";

const Staking: FC = (): JSX.Element => {
  return (
    <WalletConnectionWall>
      <StakingSharesExplorer />
    </WalletConnectionWall>
  );
};

export default Staking;
