import { ethers } from "ethers";
import { FC, useState } from "react";
import "@uniswap/widgets/fonts.css";

import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useEffectAsync from "@/components/lib/hooks/use-effect-async";
import DollarPrice from "@/components/redeem/dollar-price";
import { fetchData } from "@/components/utils/local-data";

import dynamic from "next/dynamic";
const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

const index: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const protocolContracts = useProtocolContracts();

  useEffectAsync(async () => {
    if (protocolContracts != null) {
      try {
        console.log(twapPrice, "priced in ");
      } catch (error) {
        console.log("Error occurred while executing contract call", error);
        setTwapPrice(null);
      }
    } else {
      console.log("protocolContracts is null");
      setTwapPrice(null);
    }
  }, []);

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
