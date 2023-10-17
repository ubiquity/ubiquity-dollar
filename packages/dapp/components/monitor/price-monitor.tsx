import { BigNumber, ethers } from "ethers";
import { useState } from "react";
import useEffectAsync from "../lib/hooks/use-effect-async";

import NAMED_ACCOUNTS from "../config/named-accounts.json";
import { formatEther, formatMwei } from "@/lib/format";
import useNamedContracts from "../lib/hooks/contracts/use-named-contracts";
import useProtocolContracts, { ProtocolContracts } from "@/components/lib/hooks/contracts/use-protocol-contracts";
// import Address from "./ui/Address";
import PriceExchange from "./ui/price-exchange";

type State = null | PriceMonitorProps;
type PriceMonitorProps = {
  metaPoolAddress: string;
  daiUsdt: number;
  uadUsdc: number;
  uadDai: number;
  uadUsdt: number;
  twapAddress: string;
  uadCrv: number;
  crvUad: number;
  dollarMintCalcAddress: string;
  dollarToBeMinted: number | null;
};

type NamedContracts = NonNullable<Awaited<ReturnType<typeof useNamedContracts>>>;

const fetchPrices = async (protocolContracts: ProtocolContracts, { curvePool }: NamedContracts): Promise<PriceMonitorProps | undefined> => {
  const contracts = await protocolContracts;
  if (contracts) {
    const {
      dollarToken: dollarToken,
      curveMetaPoolDollarTriPoolLp: metaPool,
      twapOracleDollar3poolFacet: twapOracle,
      dollarMintCalculatorFacet: dollarMintCalc,
    } = contracts;

    if (dollarToken && metaPool && twapOracle && dollarMintCalc) {
      const [[daiIndex, usdtIndex], [uadIndex, usdcIndex]] = await Promise.all([
        curvePool.get_coin_indices(metaPool.address, NAMED_ACCOUNTS.DAI, NAMED_ACCOUNTS.USDT),
        curvePool.get_coin_indices(metaPool.address, dollarToken.address, NAMED_ACCOUNTS.USDC),
      ]);

      const metaPoolGet = async (i1: BigNumber, i2: BigNumber): Promise<BigNumber> => {
        return await metaPool.get_dy_underlying(i1, i2, ethers.utils.parseEther("1"));
      };

      const [daiUsdt, uadUsdc, uadDai, uadUsdt, uadCrv, crvUad] = await Promise.all([
        metaPoolGet(daiIndex, usdtIndex),
        metaPoolGet(uadIndex, usdcIndex),
        metaPoolGet(uadIndex, daiIndex),
        metaPoolGet(uadIndex, usdtIndex),
        twapOracle.consult(dollarToken.address),
        twapOracle.consult(NAMED_ACCOUNTS.curve3CrvToken),
      ]);

      return {
        metaPoolAddress: metaPool.address,
        daiUsdt: +formatMwei(daiUsdt),
        uadUsdc: +formatMwei(uadUsdc),
        uadDai: +formatEther(uadDai),
        uadUsdt: +formatMwei(uadUsdt),
        twapAddress: twapOracle.address,
        uadCrv: +formatEther(uadCrv),
        crvUad: +formatEther(crvUad),
        dollarMintCalcAddress: dollarMintCalc.address,
        dollarToBeMinted: uadCrv.gt(ethers.utils.parseEther("1")) ? +formatEther(await dollarMintCalc.getDollarsToMint()) : null,
      };
    }
  }
};

const PriceMonitorContainer = () => {
  const namedContracts = useNamedContracts();
  const protocolContracts = useProtocolContracts();
  const [priceMonitorProps, setPriceMonitorProps] = useState<State>(null);

  useEffectAsync(async () => {
    if (protocolContracts && namedContracts) {
      const prices = await fetchPrices(protocolContracts, namedContracts);
      if (prices) {
        setPriceMonitorProps(prices);
      }
    }
  }, [namedContracts]);

  return priceMonitorProps && <PriceMonitor {...priceMonitorProps} />;
};

const PriceMonitor = (props: PriceMonitorProps) => {
  return (
    <div className="panel">
      <h2>Spot</h2>
      {/* cspell: disable-next-line */}
      <PriceExchange from="uAD" to="USDC" value={props.uadUsdc} />
      <h3>Time Weighted Average</h3>
      {/* cspell: disable-next-line */}
      <PriceExchange from="uAD" to="3CRV" value={props.uadCrv} />
      {/* cspell: disable-next-line */}
      <PriceExchange from="3CRV" to="uAD" value={props.crvUad} />
      <h3>Dollar Minting</h3>
      <div>
        {props.dollarToBeMinted ? (
          <div>
            {/* cspell: disable-next-line */}
            {props.dollarToBeMinted} <span> uAD</span> to be minted
          </div>
        ) : (
          "No minting needed"
        )}
      </div>
    </div>
  );
};

export default PriceMonitorContainer;
