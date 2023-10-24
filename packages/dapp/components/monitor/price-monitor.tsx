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
  dollarUsdc: number;
  dollarDai: number;
  dollarUsdt: number;
  twapAddress: string;
  dollarCrv: number;
  crvDollar: number;
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
      const [[daiIndex, usdtIndex], [dollarIndex, usdcIndex]] = await Promise.all([
        curvePool.get_coin_indices(metaPool.address, NAMED_ACCOUNTS.DAI, NAMED_ACCOUNTS.USDT),
        curvePool.get_coin_indices(metaPool.address, dollarToken.address, NAMED_ACCOUNTS.USDC),
      ]);

      const metaPoolGet = async (i1: BigNumber, i2: BigNumber): Promise<BigNumber> => {
        return await metaPool.get_dy_underlying(i1, i2, ethers.utils.parseEther("1"));
      };

      const [daiUsdt, dollarUsdc, dollarDai, dollarUsdt, dollarCrv, crvDollar] = await Promise.all([
        metaPoolGet(daiIndex, usdtIndex),
        metaPoolGet(dollarIndex, usdcIndex),
        metaPoolGet(dollarIndex, daiIndex),
        metaPoolGet(dollarIndex, usdtIndex),
        twapOracle.consult(dollarToken.address),
        twapOracle.consult(NAMED_ACCOUNTS.curve3CrvToken),
      ]);

      return {
        metaPoolAddress: metaPool.address,
        daiUsdt: +formatMwei(daiUsdt),
        dollarUsdc: +formatMwei(dollarUsdc),
        dollarDai: +formatEther(dollarDai),
        dollarUsdt: +formatMwei(dollarUsdt),
        twapAddress: twapOracle.address,
        dollarCrv: +formatEther(dollarCrv),
        crvDollar: +formatEther(crvDollar),
        dollarMintCalcAddress: dollarMintCalc.address,
        dollarToBeMinted: dollarCrv.gt(ethers.utils.parseEther("1")) ? +formatEther(await dollarMintCalc.getDollarsToMint()) : null,
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
      <PriceExchange from="DOLLAR" to="USDC" value={props.dollarUsdc} />
      <h3>Time Weighted Average</h3>
      {/* cspell: disable-next-line */}
      <PriceExchange from="Dollar" to="3CRV" value={props.dollarCrv} />
      {/* cspell: disable-next-line */}
      <PriceExchange from="3CRV" to="Dollar" value={props.crvDollar} />
      <h3>Dollar Minting</h3>
      <div>
        {props.dollarToBeMinted ? (
          <div>
            {/* cspell: disable-next-line */}
            {props.dollarToBeMinted} <span> Dollar</span> to be minted
          </div>
        ) : (
          "No minting needed"
        )}
      </div>
    </div>
  );
};

export default PriceMonitorContainer;
