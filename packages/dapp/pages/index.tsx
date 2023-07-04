import { ethers } from "ethers";
import { FC, useState } from "react";
import "@uniswap/widgets/fonts.css";

import useManagerManaged from "@/components/lib/hooks/contracts/use-manager-managed";
import useEffectAsync from "@/components/lib/hooks/use-effect-async";
import DollarPrice from "@/components/redeem/dollar-price";
import { fetchData } from "@/components/utils/local-data";

import dynamic from "next/dynamic";
const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

const index: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts != null) {
      try {
        console.log(twapPrice, "priced in ");
      } catch (error) {
        console.log("Error occurred while executing contract call", error);
        setTwapPrice(null);
      }
    } else {
      console.log("managedContracts is null");
      setTwapPrice(null);
    }
  }, [managedContracts]);

  if (process.env.DEBUG === "true") {
    fetchData();
  }

  return (
    <WalletConnectionWall>
      <DollarPrice />
    </WalletConnectionWall>
  );
};

export default index;
