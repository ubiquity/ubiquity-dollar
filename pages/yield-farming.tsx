import { FC } from "react";
import { useConnectedContext } from "../components/context/connected";
import YieldFarming from "../components/YieldFarming";

const YieldFarmingPage: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return <div>{account && <YieldFarming />}</div>;
};

export default YieldFarmingPage;
