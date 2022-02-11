import { FC } from "react";
import { useConnectedContext } from "../components/context/connected";
import BondingSharesExplorer from "../components/BondingSharesExplorer";

const LiquidityMining: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return <div>{account && <BondingSharesExplorer />}</div>;
};

export default LiquidityMining;
