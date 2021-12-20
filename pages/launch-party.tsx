import { FC } from "react";
import Header from "../components/Header";
import Whitelist, { WhitelistStatus } from "../components/launch-party/Whitelist";
import UbiquiStick from "../components/launch-party/UbiquiStick";
import BondingPool from "../components/launch-party/BondingPool";
import Liquidate from "../components/launch-party/Liquidate";

const Monitor: FC = (): JSX.Element => {
  return (
    <div>
      <div className="fixed h-screen w-screen z-10">
        <div id="grid"></div>
      </div>
      <div className="relative z-20">
        <Header section="Launch Party" href="/launch-party" />
        <Whitelist status={"not-whitelisted"} />
        <UbiquiStick />
        <BondingPool />
        <Liquidate />
      </div>
    </div>
  );
};

export default Monitor;
