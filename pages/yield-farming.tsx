import { FC } from "react";

import { useConnectedContext } from "@/lib/connected";
import { WalletNotConnected } from "@/ui";
import YieldFarming from "@/components/yield-farming";

const YieldFarmingPage: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return account ? <YieldFarming /> : WalletNotConnected;
};

export default YieldFarmingPage;
