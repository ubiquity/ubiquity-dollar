import { constrainNumber, formatTimeDiff } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/with-loaded-context";
import { BigNumber, ethers } from "ethers";
import { ChangeEvent, Dispatch, memo, SetStateAction, useEffect, useMemo, useState } from "react";
import useBalances from "../lib/hooks/use-balances";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import usePrices from "./lib/use-prices";
import { Balances } from "../lib/types";

type Actions = {
  onRedeem: () => void;
  onSwap: (amount: number, unit: string) => void;
  onBurn: (dollarAmount: string, setErrMsg: Dispatch<SetStateAction<string | undefined>>) => void;
};

type CreditNft = {
  amount: number;
  expiration: number;
  swap: { amount: number; unit: string };
};

type CreditNfts = {
  // cspell: disable-next-line
  creditNft: CreditNft[];
  // cspell: disable-next-line
  stakingShare: number;
  // cspell: disable-next-line
  creditNftAmount: number;
};

// cspell: disable-next-line
const CREDITNFT = "CREDITNFT";
// cspell: disable-next-line
const CREDIT = "CREDIT";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const CreditNftContainer = ({ protocolContracts, web3Provider, walletAddress, signer }: LoadedContext) => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction] = useTransactionLogger();
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [twapPrice, spotPrice] = usePrices();

  const actions: Actions = {
    onRedeem: () => {
      console.log("onRedeem");
    },
    onSwap: () => {
      console.log("onSwap");
    },
    onBurn: async (dollarAmount, setErrMsg) => {
      setErrMsg("");
      // cspell: disable-next-line
      await doTransaction("Burning DOLLAR...", async () => {});
    },
  };

  const priceIncreaseFormula = async (amount: number) => {
    const formula = 0.001;
    return amount * formula;
  };

  const cycleStartDate = 1637625600000;
  const creditDeprecationRate = 0.0001;
  const creditCurrentRewardPct = 0.05;
  const creditNftDeprecationRate = 0.0015;
  const creditNftCurrentRewardPct = 0.05;
  const creditNftExpirationTime = 1640217600000;
  const creditNftGovernanceRedemptionRate = 0.25;
  const dollarTotalSupply = 233000;
  const stakingShareTotalSupply = 10000;
  const creditTotalSupply = 30000;
  const creditNftTotalSupply = 12000;
  const creditNfts: CreditNfts = {
    // cspell: disable-next-line
    creditNft: [
      // cspell: disable-next-line
      { amount: 1000, expiration: 1640390400000, swap: { amount: 800, unit: "CREDIT" } },
      // cspell: disable-next-line
      { amount: 500, expiration: 1639526400000, swap: { amount: 125, unit: "CREDIT" } },
      // cspell: disable-next-line
      { amount: 666, expiration: 1636934400000, swap: { amount: 166.5, unit: "GOVERNANCE" } },
    ],
    // cspell: disable-next-line
    stakingShare: 1000,
    // cspell: disable-next-line
    creditNftAmount: 3430,
  };

  return (
    <div>
      <h2>Credit Nft</h2>
      {balances && (
        <CreditNft
          twapPrice={twapPrice}
          balances={balances}
          actions={actions}
          cycleStartDate={cycleStartDate}
          creditDeprecationRate={creditDeprecationRate}
          creditCurrentRewardPct={creditCurrentRewardPct}
          creditNftDeprecationRate={creditNftDeprecationRate}
          creditNftCurrentRewardPct={creditNftCurrentRewardPct}
          creditNftExpirationTime={creditNftExpirationTime}
          creditNftGovernanceRedemptionRate={creditNftGovernanceRedemptionRate}
          priceIncreaseFormula={priceIncreaseFormula}
          dollarTotalSupply={dollarTotalSupply}
          stakingShareSupply={stakingShareTotalSupply}
          creditTotalSupply={creditTotalSupply}
          creditNftTotalSupply={creditNftTotalSupply}
          creditNfts={creditNfts}
        />
      )}
    </div>
  );
};

type CreditNftProps = {
  twapPrice: BigNumber | null;
  balances: Balances;
  actions: Actions;
  cycleStartDate: number;
  creditDeprecationRate: number;
  creditCurrentRewardPct: number;
  creditNftDeprecationRate: number;
  creditNftCurrentRewardPct: number;
  creditNftExpirationTime: number;
  creditNftGovernanceRedemptionRate: number;
  dollarTotalSupply: number;
  stakingShareSupply: number;
  creditTotalSupply: number;
  creditNftTotalSupply: number;
  creditNfts: CreditNfts | null;
  priceIncreaseFormula: (amount: number) => Promise<number>;
};

const CreditNft = memo(
  ({
    twapPrice,
    actions,
    cycleStartDate,
    creditDeprecationRate,
    creditCurrentRewardPct,
    creditNftDeprecationRate,
    creditNftCurrentRewardPct,
    creditNftExpirationTime,
    creditNftGovernanceRedemptionRate,
    dollarTotalSupply,
    stakingShareSupply,
    creditTotalSupply,
    creditNftTotalSupply,
    creditNfts,
    priceIncreaseFormula,
  }: CreditNftProps) => {
    const [formattedSwapPrice, setFormattedSwapPrice] = useState("");
    // cspell: disable-next-line
    const [selectedCurrency, selectCurrency] = useState(CREDITNFT);
    const [increasedValue, setIncreasedValue] = useState(0);
    const [errMsg, setErrMsg] = useState<string>();
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [expectedCreditNft, setExpectedCreditNft] = useState<BigNumber>();
    const [dollarAmount, setDollarAmount] = useState("");

    const handleTabSelect = (tab: string) => {
      selectCurrency(tab);
    };

    useEffect(() => {
      if (twapPrice) {
        setFormattedSwapPrice(parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(2));
        // setFormattedSwapPrice("1.06");
      }
    }, [twapPrice]);

    const calculatedCycleStartDate = useMemo(() => {
      if (cycleStartDate) {
        const diff = Date.now() - cycleStartDate;
        return formatTimeDiff(diff);
      }
    }, [cycleStartDate]);

    const calculatedCreditNftExpirationTime = useMemo(() => {
      if (creditNftExpirationTime) {
        const diff = creditNftExpirationTime - Date.now();
        return formatTimeDiff(diff);
      }
    }, [creditNftExpirationTime]);

    const handleInputDOLLAR = async (e: ChangeEvent) => {
      setErrMsg("");
      const missing = `Missing input value for`;
      const bignumberErr = `can't parse BigNumber from`;
      // cspell: disable-next-line
      const subject = `DOLLAR amount`;
      const amountEl = e.target as HTMLInputElement;
      const amountValue = amountEl?.value;
      if (!amountValue) {
        setErrMsg(`${missing} ${subject}`);
        return;
      }
      if (BigNumber.isBigNumber(amountValue)) {
        setErrMsg(`${bignumberErr} ${subject}`);
        return;
      }
      const amount = ethers.utils.parseEther(amountValue);
      if (!amount.gt(BigNumber.from(0))) {
        setErrMsg(`${subject} should be greater than 0`);
        return;
      }
      setDollarAmount(amountValue);
    };

    const handleBurn = () => {
      actions.onBurn(dollarAmount, setErrMsg);
    };

    const isLessThanOne = () => parseFloat(formattedSwapPrice) <= 1;

    useEffect(() => {
      if (dollarAmount) {
        // _expectedCreditNft(dollarAmount, contracts, selectedCurrency, setExpectedCreditNft);
      }
    }, [dollarAmount, selectedCurrency]);

    useEffect(() => {
      priceIncreaseFormula(10).then((value) => {
        setIncreasedValue(value);
      });
    });

    return (
      <>
        <TwapPriceBar price={formattedSwapPrice} date={calculatedCycleStartDate} />
        {isLessThanOne() ? (
          <>
            <PumpCycle
              creditDeprecationRate={creditDeprecationRate}
              creditCurrentRewardPct={creditCurrentRewardPct}
              creditNftDeprecationRate={creditNftDeprecationRate}
              creditNftCurrentRewardPct={creditNftCurrentRewardPct}
              creditNftGovernanceRedemptionRate={creditNftGovernanceRedemptionRate}
              calculatedCreditNftExpirationTime={calculatedCreditNftExpirationTime}
            />
            <DollarBurning
              handleInputDOLLAR={handleInputDOLLAR}
              selectedCurrency={selectedCurrency}
              handleTabSelect={handleTabSelect}
              handleBurn={handleBurn}
              errMsg={errMsg}
              expectedCreditNft={expectedCreditNft}
              increasedValue={increasedValue}
            />
          </>
        ) : (
          <CreditNfts
            dollarTotalSupply={dollarTotalSupply}
            stakingShareSupply={stakingShareSupply}
            creditTotalSupply={creditTotalSupply}
            creditNftTotalSupply={creditNftTotalSupply}
            creditNfts={creditNfts}
            actions={actions}
          />
        )}
      </>
    );
  }
);

type CreditNftsProps = {
  dollarTotalSupply: number;
  stakingShareSupply: number;
  creditTotalSupply: number;
  creditNftTotalSupply: number;
  creditNfts: CreditNfts | null;
  actions: Actions;
};

export const CreditNfts = ({ dollarTotalSupply, stakingShareSupply, creditTotalSupply, creditNftTotalSupply, creditNfts, actions }: CreditNftsProps) => {
  return (
    <>
      <RewardCycleInfo
        dollarTotalSupply={dollarTotalSupply}
        stakingShareSupply={stakingShareSupply}
        creditTotalSupply={creditTotalSupply}
        creditNftTotalSupply={creditNftTotalSupply}
      />
      <div>
        <span>Your CreditNfts</span>
      </div>
      <CreditNftRedeem creditNfts={creditNfts} actions={actions} />
      <CreditNftTable creditNfts={creditNfts} onRedeem={actions.onRedeem} onSwap={actions.onSwap} />
    </>
  );
};

type CreditNftRedeemProps = {
  creditNfts: CreditNfts | null;
  actions: Actions;
};

export const CreditNftRedeem = ({ creditNfts, actions }: CreditNftRedeemProps) => {
  const [creditAmount, setCreditAmount] = useState("");
  const [stakingShareAmount, setStakingShareAmount] = useState("");
  const shouldDisableInput = (type: keyof CreditNfts) => {
    if (!creditNfts) {
      return true;
      // cspell: disable-next-line
    } else if (type === "creditNftAmount") {
      // cspell: disable-next-line
      return !creditNfts.creditNftAmount || creditNfts.creditNftAmount <= 0;
      // cspell: disable-next-line
    } else if (type === "stakingShare") {
      // cspell: disable-next-line
      return !creditNfts.stakingShare || creditNfts.stakingShare <= 0;
    }
    return false;
  };

  const handleInputCREDIT = async (e: ChangeEvent) => {
    // cspell: disable-next-line
    if (!creditNfts || !creditNfts.creditNftAmount) {
      return;
    }
    const amountEl = e.target as HTMLInputElement;
    const amountValue = amountEl?.value;
    // cspell: disable-next-line
    setCreditAmount(`${constrainNumber(parseFloat(amountValue), 0, creditNfts.creditNftAmount)}`);
  };

  const handleInputStakingShare = async (e: ChangeEvent) => {
    // cspell: disable-next-line
    if (!creditNfts || !creditNfts.stakingShare) {
      return;
    }
    const amountEl = e.target as HTMLInputElement;
    const amountValue = amountEl?.value;
    // cspell: disable-next-line
    setStakingShareAmount(`${constrainNumber(parseFloat(amountValue), 0, creditNfts.stakingShare)}`);
  };

  const creditToCreditNftFormula = (amount: string) => {
    const parsedValue = parseFloat(amount);
    return isNaN(parsedValue) ? 0 : parsedValue * 0.9;
  };

  return (
    <>
      <div>
        <div>
          <div>
            <div>
              {/* cspell: disable-next-line */}
              <span>Staking Share {creditNfts?.stakingShare.toLocaleString()}</span>
            </div>
            <div>
              {/* cspell: disable-next-line */}
              <input type="number" value={stakingShareAmount} disabled={shouldDisableInput("stakingShare")} onChange={handleInputStakingShare} />
              <button onClick={actions.onRedeem}>Redeem</button>
            </div>
          </div>
        </div>
        <div>
          <div>
            <div>
              {/* cspell: disable-next-line */}
              <span>CREDIT {creditNfts?.creditNftAmount.toLocaleString()} - $2,120</span>
            </div>
            <div>
              {/* cspell: disable-next-line */}
              <input type="number" value={creditAmount} disabled={shouldDisableInput("creditNftAmount")} onChange={handleInputCREDIT} />
              <button onClick={actions.onRedeem}>Redeem</button>
            </div>
          </div>
        </div>
        <div>
          <div>
            <div>
              <span>Deprecation rate 10% / week</span>
            </div>
            <div>
              {/* cspell: disable-next-line */}
              <span>{creditToCreditNftFormula(creditAmount).toLocaleString()} CREDIT NFT</span>
              {/* cspell: disable-next-line */}
              <button onClick={() => actions.onSwap(2120, CREDITNFT)}>Swap</button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

type RewardCycleInfoProps = {
  dollarTotalSupply: number;
  stakingShareSupply: number;
  creditTotalSupply: number;
  creditNftTotalSupply: number;
};

export const RewardCycleInfo = ({ dollarTotalSupply, stakingShareSupply, creditTotalSupply, creditNftTotalSupply }: RewardCycleInfoProps) => {
  return (
    <>
      <div>
        <span>Reward Cycle</span>
      </div>
      <div>
        <div>
          <div>
            {/* cspell: disable-next-line */}
            <span>DOLLAR</span>
          </div>
          <div>
            <div>Total Supply</div>
            <div>{dollarTotalSupply.toLocaleString()}</div>
          </div>
          <div>
            <div>Minted</div>
            <div>25k</div>
          </div>
          <div>
            <div>Mintable</div>
            <div>12k</div>
          </div>
        </div>
      </div>
      <div>
        <div>
          <div>
            <span>Total Credit NFT</span>
          </div>
          <div>
            <div>
              {/* cspell: disable-next-line */}
              <div>stakingShare</div>
              <div>{stakingShareSupply.toLocaleString()}</div>
            </div>
            <div>
              {/* cspell: disable-next-line */}
              <div>CREDIT</div>
              <div>{creditTotalSupply.toLocaleString()}</div>
            </div>
            <div>
              {/* cspell: disable-next-line */}
              <div>CREDIT NFT</div>
              <div>{creditNftTotalSupply.toLocaleString()}</div>
            </div>
          </div>
        </div>
      </div>
      <div>
        <div>
          <div>
            <span>Redeemable</span>
          </div>
          <div>
            <div>10,000</div>
            <div>27,000</div>
            <div>0</div>
          </div>
        </div>
      </div>
    </>
  );
};

type DollarBurningProps = {
  selectedCurrency: string;
  errMsg: string | undefined;
  expectedCreditNft: BigNumber | undefined;
  increasedValue: number;
  handleInputDOLLAR: (e: ChangeEvent) => Promise<void>;
  handleTabSelect: (tab: string) => void;
  handleBurn: () => void;
};

export const DollarBurning = ({
  handleInputDOLLAR,
  selectedCurrency,
  handleTabSelect,
  handleBurn,
  increasedValue,
  expectedCreditNft,
  errMsg,
}: DollarBurningProps) => {
  return (
    <>
      <div>
        {/* cspell: disable-next-line */}
        <span>DOLLAR</span>
        <input type="number" onChange={handleInputDOLLAR} />
        <nav>
          {/* cspell: disable-next-line */}
          <button onClick={() => handleTabSelect(CREDIT)}>CREDIT</button>
          {/* cspell: disable-next-line */}
          <button onClick={() => handleTabSelect(CREDITNFT)}>CREDIT NFT</button>
        </nav>
        <button onClick={handleBurn}>Burn</button>
      </div>
      <p>{errMsg}</p>
      {expectedCreditNft && (
        <p>
          expected {selectedCurrency} {ethers.utils.formatEther(expectedCreditNft)}
        </p>
      )}
      <div>
        <span>Price will increase by an estimated of +${increasedValue}</span>
      </div>
    </>
  );
};

type PumpCycleProps = {
  creditDeprecationRate: number;
  creditCurrentRewardPct: number;
  creditNftDeprecationRate: number;
  creditNftCurrentRewardPct: number;
  creditNftGovernanceRedemptionRate: number;
  calculatedCreditNftExpirationTime: string | undefined;
};

export const PumpCycle = ({
  creditDeprecationRate,
  creditCurrentRewardPct,
  creditNftDeprecationRate,
  creditNftCurrentRewardPct,
  creditNftGovernanceRedemptionRate,
  calculatedCreditNftExpirationTime,
}: PumpCycleProps) => {
  return (
    <>
      <div>
        <span>Pump Cycle</span>
      </div>
      <div>
        <div>
          {/* cspell: disable-next-line */}
          <span>Fungible (CREDIT)</span>
          <table>
            <tbody>
              <tr>
                <td>Deprecation rate</td>
                <td>{creditDeprecationRate * 100}% / week</td>
              </tr>
              <tr>
                <td>Current reward %</td>
                <td>{creditCurrentRewardPct * 100}%</td>
              </tr>
              <tr>
                <td>Expires?</td>
                <td>No</td>
              </tr>
            </tbody>
          </table>
          <div>
            <span>Higher priority when redeeming</span>
          </div>
          <a href="">Learn more</a>
        </div>
        <div>
          {/* cspell: disable-next-line */}
          <span>Non-fungible (CREDIT NFT)</span>
          <table>
            <tbody>
              <tr>
                <td>Deprecation rate</td>
                <td>{creditNftDeprecationRate * 100}%</td>
              </tr>
              <tr>
                <td>Current reward %</td>
                <td>{creditNftCurrentRewardPct * 100}%</td>
              </tr>
              <tr>
                <td>Expires?</td>
                <td>After {calculatedCreditNftExpirationTime}</td>
              </tr>
            </tbody>
          </table>
          <div>
            <span>Convertible to fungible</span>
          </div>
          <div>
            {/* cspell: disable-next-line */}
            <span>Can be redeemed for GOVERNANCE at {creditNftGovernanceRedemptionRate * 100}% rate</span>
          </div>
          <a href="">Learn more</a>
        </div>
      </div>
    </>
  );
};

type TwapPriceBarProps = {
  price: string;
  date: string | undefined;
};

export const TwapPriceBar = ({ price, date }: TwapPriceBarProps) => {
  const leftPositioned = parseFloat(price) <= 1;

  return (
    <>
      <div>
        <div>
          <div></div>
          <hr />
          <div>{leftPositioned ? <span>${price}</span> : <span>Redeeming cycle started {date} ago</span>}</div>
          {leftPositioned ? (
            <>
              <div>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </div>
              <hr />
            </>
          ) : (
            <>
              <hr />
              <div>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16l-4-4m0 0l4-4m-4 4h18" />
                </svg>
              </div>
            </>
          )}
          <div>{leftPositioned ? <span>Pump cycle started {date} ago</span> : <span>${price}</span>}</div>
          <hr />
          <div></div>
        </div>
      </div>
      <div>
        <div>
          <span>$0.9</span>
        </div>
        <div>
          <span>$1</span>
        </div>
        <div>
          <span>$1.1</span>
        </div>
      </div>
      <div>
        <span>
          {/* cspell: disable-next-line */}
          {parseFloat(price) <= 1 ? "Burn DOLLAR for credit nfts and help pump the price back up" : "Time to redeem credits nfts and help move the price down"}
        </span>
      </div>
    </>
  );
};

type CreditNftTableProps = {
  creditNfts: CreditNfts | null;
  onRedeem: Actions["onRedeem"];
  onSwap: Actions["onSwap"];
};

export const CreditNftTable = ({ creditNfts, onRedeem, onSwap }: CreditNftTableProps) => {
  return (
    <div>
      <table>
        <thead>
          <tr>
            {/* cspell: disable-next-line */}
            <th>CREDIT NFT</th>
            <th>Expiration</th>
            <th>Swap</th>
            <th></th>
          </tr>
        </thead>

        <tbody>
          {/* cspell: disable-next-line */}
          {creditNfts && creditNfts.creditNft && creditNfts.creditNft.length
            ? // cspell: disable-next-line
              creditNfts.creditNft.map((creditNft, index) => <CreditNftRow creditNft={creditNft} onRedeem={onRedeem} onSwap={onSwap} key={index} />)
            : null}
        </tbody>
      </table>
    </div>
  );
};

type CreditNftRowProps = {
  creditNft: CreditNft;
  onRedeem: Actions["onRedeem"];
  onSwap: Actions["onSwap"];
};

export const CreditNftRow = ({ creditNft, onRedeem, onSwap }: CreditNftRowProps) => {
  const timeDiff = creditNft.expiration - Date.now();

  const handleSwap = () => {
    onSwap(creditNft.swap.amount, creditNft.swap.unit);
  };

  return (
    <tr>
      <td>{creditNft.amount.toLocaleString()}</td>
      <td>
        {formatTimeDiff(Math.abs(timeDiff))}
        {timeDiff < 0 ? " ago" : ""}
      </td>
      <td>
        <button onClick={handleSwap}>{`${creditNft.swap.amount.toLocaleString()} ${creditNft.swap.unit}`}</button>
      </td>
      <td>{timeDiff > 0 ? <button onClick={onRedeem}>Redeem</button> : null}</td>
    </tr>
  );
};

export default withLoadedContext(CreditNftContainer);
