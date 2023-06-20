import { FC } from "react";
import BondingSharesExplorer from "@/components/staking/BondingSharesExplorer";
import dynamic from "next/dynamic";
const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

const Staking: FC = (): JSX.Element => {
  return (
    <WalletConnectionWall>
      <BondingSharesExplorer />
    </WalletConnectionWall>
  );
};

export default Staking;
