import { FC } from "react";
import BondingSharesExplorer from "@/components/staking/BondingSharesExplorer";
import WalletConnectionWall from "@/components/ui/WalletConnectionWall";

const Staking: FC = (): JSX.Element => {
  return (
    <WalletConnectionWall>
      <BondingSharesExplorer />
    </WalletConnectionWall>
  );
};

export default Staking;
