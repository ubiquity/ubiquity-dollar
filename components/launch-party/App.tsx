import { RecoilRoot } from "recoil";
import Header from "../Header";
import CustomHeader from "./Header";
import Whitelist from "./Whitelist";
import UbiquiStick from "./UbiquiStick";
import FundingPools from "./FundingPools";
import MultiplicationPool from "./MultiplicationPool";
import YourBonds from "./YourBonds";
import Liquidate from "./Liquidate";

const App = () => {
  return (
    <div>
      <Header section="Launch Party" href="/launch-party" />
      <CustomHeader />
      <Whitelist />
      <UbiquiStick />
      <FundingPools />
      <MultiplicationPool />
      <YourBonds />
      <Liquidate accumulated={3500} />
    </div>
  );
};

const RecoilApp = () => (
  <RecoilRoot>
    <App />
  </RecoilRoot>
);

export default RecoilApp;
