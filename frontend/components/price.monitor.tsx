import { ethers, BigNumber } from "ethers";

import { useEffect, useState } from "react";
import { ADDRESS, Contracts } from "../src/contracts";
import { useConnectedContext } from "./context/connected";

const formatMwei = (n: BigNumber, round = 1e5): string => {
  return (
    Math.round(+ethers.utils.formatUnits(n, "mwei") * round) / round
  ).toString();
};

const formatEther = (n: BigNumber, round = 1e5): string => {
  return (Math.round(+ethers.utils.formatEther(n) * round) / round).toString();
};

type State = null | PriceMonitorProps;
type PriceMonitorProps = {
  daiUsdt: BigNumber;
  uadUsdc: BigNumber;
  uadDai: BigNumber;
  uadUsdt: BigNumber;
  uadCrv: BigNumber;
  crvUad: BigNumber;
  dollarToBeMinted: BigNumber | null;
};

const fetchPrices = async ({
  uad,
  curvePool,
  metaPool,
  twapOracle,
  dollarMintCalc,
}: Contracts): Promise<PriceMonitorProps> => {
  const [[daiIndex, usdtIndex], [uadIndex, usdcIndex]] = await Promise.all([
    curvePool.get_coin_indices(metaPool.address, ADDRESS.DAI, ADDRESS.USDT),
    curvePool.get_coin_indices(metaPool.address, uad.address, ADDRESS.USDC),
  ]);

  const metaPoolGet = async (
    i1: BigNumber,
    i2: BigNumber
  ): Promise<BigNumber> => {
    return await metaPool["get_dy_underlying(int128,int128,uint256)"](
      i1,
      i2,
      ethers.utils.parseEther("1")
    );
  };

  const [
    daiUsdt,
    uadUsdc,
    uadDai,
    uadUsdt,
    uadCrv,
    crvUad,
  ] = await Promise.all([
    metaPoolGet(daiIndex, usdtIndex),
    metaPoolGet(uadIndex, usdcIndex),
    metaPoolGet(uadIndex, daiIndex),
    metaPoolGet(uadIndex, usdtIndex),
    twapOracle.consult(uad.address),
    twapOracle.consult(ADDRESS.curve3CrvToken),
  ]);

  return {
    daiUsdt,
    uadUsdc,
    uadDai,
    uadUsdt,
    uadCrv,
    crvUad,
    dollarToBeMinted: uadCrv.gt(ethers.utils.parseEther("1"))
      ? await dollarMintCalc.getDollarsToMint()
      : null,
  };
};

const PriceMonitorContainer = () => {
  const { contracts } = useConnectedContext();
  const [priceMonitorProps, setPriceMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (contracts) {
      (async function () {
        setPriceMonitorProps(await fetchPrices(contracts));
      })();
    }
  }, [contracts]);

  return priceMonitorProps && <PriceMonitor {...priceMonitorProps} />;
};

const PriceMonitor = (props: PriceMonitorProps) => {
  return (
    <div className="!block !mx-0 !py-8 text-white text-opacity-50 tracking-wide">
      <div className="text-center uppercase mb-8 tracking-3px text-14px">
        Price monitor
      </div>
      <div className="max-w-screen-md mx-auto mb-4">
        {priceInfoView("DAI", "USDT", formatMwei(props.daiUsdt))}
        {priceInfoView("uAD", "USDC", formatMwei(props.uadUsdc))}
        {priceInfoView("uAD", "DAI", formatEther(props.uadDai))}
        {priceInfoView("uAD", "USDT", formatMwei(props.uadUsdt))}
        {priceInfoView("uAD", "3CRV", formatEther(props.uadCrv))}
        {priceInfoView("3CRV", "uAD", formatEther(props.crvUad))}
      </div>
      {props.dollarToBeMinted ? (
        <div className="text-center">
          Dollars to be minted
          <div>
            {formatEther(props.dollarToBeMinted)}{" "}
            <span className="text-white text-opacity-75"> uAD</span>
          </div>
        </div>
      ) : (
        "No minting needed"
      )}
    </div>
  );
};

const priceInfoView = (from: string, to: string, value: string) => (
  <div className="flex">
    <span className="w-1/2 text-right">
      1 <span className="text-white text-opacity-75">{from}</span>
    </span>
    <span className="w-8 -mt-1 text-center">⇄</span>
    <span className="w-1/2 flex-grow text-left">
      {value.toString()}{" "}
      <span className="text-white text-opacity-75">{to}</span>
    </span>
  </div>
);

export default PriceMonitorContainer;
