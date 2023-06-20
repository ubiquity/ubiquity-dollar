import { ethers } from "ethers";
import { FC, useState } from "react";
import "@uniswap/widgets/fonts.css";

import useManagerManaged from "@/components/lib/hooks/contracts/use-manager-managed";
import useEffectAsync from "@/components/lib/hooks/use-effect-async";
import DollarPrice from "@/components/redeem/dollar-price";

import dynamic from "next/dynamic";
const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

const index: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address));
    }
  }, [managedContracts]);

  return (
    <WalletConnectionWall>
      <DollarPrice />
    </WalletConnectionWall>
  );
};

export default index;
