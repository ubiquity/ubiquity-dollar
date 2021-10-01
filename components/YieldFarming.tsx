import { memo } from "react";
import { connectedWithUserContext } from "./context/connected";
import * as widget from "./ui/widget";
import { WarningIcon, HelpIcon } from "./ui/icons";

export const YieldFarmingContainer = () => {
  return <YieldFarming />;
};

export const YieldFarming = memo(() => {
  return (
    <widget.Container className="max-w-screen-md !mx-auto relative">
      <widget.Title text="Deposit" />
      <div className="flex justify-evenly items-center p-4 border border-white/10 border-solid rounded-md mb-4">
        <div>{WarningIcon}</div>
        <p className="text-left">
          uAR is 1:1 redeemabnle for uAD when our TWAP goes above 1.00. <span className="text-accent">Click</span> to learn more
        </p>
      </div>
      <div className="flex justify-between items-center mb-8">
        <div className="w-5/12">
          <p className="flex justify-between">
            <span>USDC</span>
            <span>
              <span>TVL</span>
              <span className="pl-4">1.2M</span>
            </span>
          </p>
          <p className="text-left">
            <span>14.18% - 27.07%</span>
            <span className="pl-4">APY</span>
            <span className="pl-2">{HelpIcon}</span>
          </p>
          <input type="text" placeholder="2,000" className="w-full m-0 box-border" />
        </div>
        <div className="w-1/2">
          <p className="text-2xl font-bold">40.59%</p>
          <p>
            Max APY in uAR<span className="pl-2">{HelpIcon}</span>
          </p>
        </div>
      </div>
      <widget.SubTitle text="Boosters" />
      <div className="flex justify-between items-center mb-4">
        <div className="w-5/12">
          <p className="flex justify-between w-10/12">
            <span>UBQ</span>
            <span>
              <span>TVL</span>
              <span className="pl-4">2.5M</span>
            </span>
          </p>
          <p className="text-left flex justify-between w-10/12 items-center my-2">
            <span>Minimizes depoist fee</span>
            <span>{HelpIcon}</span>
          </p>
          <div className="flex justify-between items-center">
            <input type="text" placeholder="Max 10,000" className="w-10/12 m-0 box-border" />
            <span>10%</span>
          </div>
          <div className="w-10/12 flex justify-end mt-2">
            <span className="text-accent">Max</span>
          </div>
        </div>
        <div className="w-5/12">
          <p className="flex justify-between w-10/12">
            <span>UAD</span>
            <span className="pl-4">
              <span>TVL</span>
              <span className="pl-4">0.6M</span>
            </span>
          </p>
          <p className="text-left flex justify-between w-10/12 items-center my-2">
            <span>Multiples yield up to 50%</span>
            <span>{HelpIcon}</span>
          </p>
          <div className="flex justify-between items-center">
            <input type="text" placeholder="Max 50% of deposit" className="w-10/12 m-0 box-border" />
            <span>10%</span>
          </div>
          <div className="w-10/12 flex justify-end mt-2">
            <span className="text-accent">Max</span>
          </div>
        </div>
      </div>
      <button className="w-full flex justify-center m-0 mt-8">Deposit</button>
    </widget.Container>
  );
});

export default connectedWithUserContext(YieldFarmingContainer);
