import { ethers, BigNumber } from "ethers";
import { useEffect, useState } from "react";
import { ADDRESS, Contracts } from "../src/contracts";
import { useConnectedContext } from "./context/connected";
import { formatEther, formatMwei } from "../utils/format";
import * as widget from "./ui/widget";

type State = null | PriceMonitorProps;
type PriceMonitorProps = {
  daiUsdt: number;
  uadUsdc: number;
  uadDai: number;
  uadUsdt: number;
  uadCrv: number;
  crvUad: number;
  dollarToBeMinted: number | null;
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
    daiUsdt: +formatMwei(daiUsdt),
    uadUsdc: +formatMwei(uadUsdc),
    uadDai: +formatEther(uadDai),
    uadUsdt: +formatEther(uadUsdt),
    uadCrv: +formatEther(uadCrv),
    crvUad: +formatEther(crvUad),
    dollarToBeMinted: uadCrv.gt(ethers.utils.parseEther("1"))
      ? +formatEther(await dollarMintCalc.getDollarsToMint())
      : 1043,
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
    <widget.Container>
      <widget.Title text="Price monitor" />
      <widget.PriceExchange from="DAI" to="USDT" value={props.daiUsdt} />
      <widget.PriceExchange from="uAD" to="USDC" value={props.uadUsdc} />
      <widget.PriceExchange from="uAD" to="DAI" value={props.uadDai} />
      <widget.PriceExchange from="uAD" to="USDT" value={props.uadUsdt} />
      <widget.SubTitle text="Time Weighted Average" />
      <widget.PriceExchange from="uAD" to="3CRV" value={props.uadCrv} />
      <widget.PriceExchange from="3CRV" to="uAD" value={props.crvUad} />
      <div className="text-center mt-4">
        {props.dollarToBeMinted ? (
          <>
            Dollars to be minted
            <div>
              {props.dollarToBeMinted}{" "}
              <span className="text-white text-opacity-75"> uAD</span>
            </div>
          </>
        ) : (
          "No minting needed"
        )}
      </div>
    </widget.Container>
  );
};

export default PriceMonitorContainer;
