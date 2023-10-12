import { FC } from "react";
import StakingSharesExplorer from "@/components/staking/staking-shares-explorer";
import dynamic from "next/dynamic";
const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

const Staking: FC = (): JSX.Element => {
  return (
    <WalletConnectionWall>
      <StakingSharesExplorer />
    </WalletConnectionWall>
  );
};

export default Staking;
