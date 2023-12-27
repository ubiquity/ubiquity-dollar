import dynamic from "next/dynamic";
import { FC } from "react";

const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

/**
 * UbiquityPool page
 *
 * Allows users to:
 * 1. Send collateral tokens to the pool in exchange for Dollar tokens (mint)
 * 2. Send Dollar tokens to the pool in exchange for collateral (redeem)
 */
const Pool: FC = (): JSX.Element => {
  return (
    <WalletConnectionWall>
      <div>Pool</div>
    </WalletConnectionWall>
  );
};

export default Pool;
