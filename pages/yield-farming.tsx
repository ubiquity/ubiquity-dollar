import { FC } from "react";
import { useConnectedContext } from "../components/context/connected";
import YieldFarming from "../components/YieldFarming";
import { WalletNotConnected } from "../components/ui/widget";

const YieldFarmingPage: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return account ? <YieldFarming /> : WalletNotConnected;
};

export default YieldFarmingPage;
