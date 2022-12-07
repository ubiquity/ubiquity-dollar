import { BigNumber, ethers } from "ethers";
import { useState } from "react";

import { constrainNumber } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/withLoadedContext";
import Button from "../ui/Button";
import PositiveNumberInput from "../ui/PositiveNumberInput";
import icons from "@/ui/icons";
import TokenAmountInput from "../ui/TokenAmountInput";

import useBalances, { Balances } from "../lib/hooks/useBalances";
const MIN_WEEKS = 1;
const MAX_WEEKS = 208;

type DepositStablesProps = {
  onApeIn: ({ amounts, weeks }: { amounts: BigNumber[]; weeks: BigNumber }) => void;
  disabled: boolean;
  maxLp: BigNumber;
} & LoadedContext;

const DepositStables = ({ onApeIn, disabled }: DepositStablesProps) => {
  const [balances, refreshBalances] = useBalances();
  const [UADAmount, setUADAmount] = useState("");
  const [DAIAmount, setDAIAmount] = useState("");
  const [USDCAmount, setUSDCAmount] = useState("");
  const [USDTAmount, setUSDTAmount] = useState("");
  const [weeks, setWeeks] = useState("");

  function validateAmounts(): string[] | null {
    console.log("validateAmounts");
    const errorsLabel = [];
    if (UADAmount || DAIAmount || USDCAmount || USDTAmount) {
      console.log("validateAmounts UADAmount", UADAmount);
      if (UADAmount) {
        try {
          const amountUADBig = ethers.utils.parseEther(UADAmount);
          const maxUAD = balances ? (balances as Balances)["uad"] : BigNumber.from(0);
          if (amountUADBig.gt(maxUAD)) errorsLabel.push(`You don't have enough $uAD tokens`);
        } catch {
          errorsLabel.push(`Incorrect $uAD value`);
        }
      }
      console.log("validateAmounts DAIAmount", DAIAmount);
      if (DAIAmount) {
        try {
          const amountDAIBig = ethers.utils.parseEther(DAIAmount);
          const maxDAI = balances ? (balances as Balances)["dai"] : BigNumber.from(0);
          if (amountDAIBig.gt(maxDAI)) errorsLabel.push(`You don't have enough $DAI tokens`);
        } catch {
          errorsLabel.push(`Incorrect $USDC value`);
        }
      }
      console.log("validateAmounts USDCAmount", USDCAmount);
      if (USDCAmount) {
        try {
          const amountUSDCBig = ethers.utils.parseUnits(USDCAmount, 6);
          const maxUSDC = balances ? (balances as Balances)["usdc"] : BigNumber.from(0);
          if (amountUSDCBig.gt(maxUSDC)) errorsLabel.push(`You don't have enough $USDC tokens`);
        } catch {
          errorsLabel.push(`Incorrect $USDC value`);
        }
      }
      console.log("validateAmounts USDTAmount", USDTAmount);
      if (USDTAmount) {
        try {
          const amountUSDTBig = ethers.utils.parseUnits(USDTAmount, 6);
          const maxUSDT = balances ? (balances as Balances)["usdt"] : BigNumber.from(0);
          if (amountUSDTBig.gt(maxUSDT)) errorsLabel.push(`You don't have enough $USDT tokens`);
        } catch {
          errorsLabel.push(`Incorrect $USDT value`);
        }
      }
      console.log(errorsLabel);
      return errorsLabel.length > 0 ? errorsLabel : null;
    }
    return null;
  }

  const error = validateAmounts();
  const hasErrors = !!error;

  const onWeeksChange = (inputVal: string) => {
    setWeeks(inputVal && constrainNumber(parseInt(inputVal), MIN_WEEKS, MAX_WEEKS).toString());
  };

  const onUADAmountChange = (inputVal: string) => {
    console.log("onUADAmountChange", inputVal);
    setUADAmount(inputVal);
    console.log("UADAmount", UADAmount, disabled);
  };
  const onDAIAmountChange = (inputVal: string) => {
    console.log("onDAIAmountChange", inputVal);
    setDAIAmount(inputVal);
  };
  const onUSDCAmountChange = (inputVal: string) => {
    console.log("onUSDCAmountChange", inputVal);
    setUSDCAmount(inputVal);
  };
  const onUSDTAmountChange = (inputVal: string) => {
    console.log("onUSDTAmountChange", inputVal);
    setUSDTAmount(inputVal);
  };
  const onClickStake = () => {
    console.log("🐵 🐒 🦍 🦧 APE IN !");
    onApeIn({
      amounts: [
        ethers.utils.parseUnits(USDTAmount, 6),
        ethers.utils.parseEther(UADAmount),
        ethers.utils.parseEther(DAIAmount),
        ethers.utils.parseUnits(USDCAmount, 6),
      ],
      weeks: BigNumber.from(weeks),
    });
    refreshBalances();
  };

  const onClickMax = () => {
    setUADAmount(ethers.utils.formatEther((balances as Balances)["uad"]));
    setDAIAmount(ethers.utils.formatEther((balances as Balances)["dai"]));
    setUSDCAmount(ethers.utils.formatUnits((balances as Balances)["usdc"], 6));
    setUSDTAmount(ethers.utils.formatUnits((balances as Balances)["usdt"], 6));
    setWeeks(MAX_WEEKS.toString());
  };

  // used to verify that at least one amount is valid + weeks amount
  const amountsParsed =
    ((UADAmount ?? !isNaN(parseFloat(UADAmount))) ||
      (DAIAmount ?? !isNaN(parseFloat(DAIAmount))) ||
      (USDCAmount ?? !isNaN(parseFloat(USDCAmount))) ||
      (USDTAmount ?? !isNaN(parseFloat(USDTAmount)))) &&
    (weeks ?? !isNaN(parseInt(weeks)));

  return (
    <div className="panel">
      <h2>Stake stable coins to receive UBQ</h2>

      <div style={{ display: "flex", flexDirection: "row", flexWrap: "wrap", justifyContent: "flex-end", alignItems: "center" }}>
        <TokenAmountInput
          value={UADAmount}
          max={balances ? (balances as Balances)["uad"] : BigNumber.from(0)}
          onChange={onUADAmountChange}
          disabled={disabled}
          placeholder="uAD Tokens"
          icon={() => icons.SVGs.uad}
          label="uAD"
          decimals={18}
        />
        <TokenAmountInput
          value={DAIAmount}
          max={balances ? (balances as Balances)["dai"] : BigNumber.from(0)}
          onChange={onDAIAmountChange}
          disabled={disabled}
          placeholder="dai Tokens"
          icon={() => icons.SVGs.dai}
          label="DAI"
          decimals={18}
        />
        <TokenAmountInput
          value={USDCAmount}
          max={balances ? (balances as Balances)["usdc"] : BigNumber.from(0)}
          onChange={onUSDCAmountChange}
          disabled={disabled}
          placeholder="usdc Tokens"
          icon={() => icons.SVGs.usdc}
          label="USDC"
          decimals={6}
        />
        <TokenAmountInput
          value={USDTAmount}
          max={balances ? (balances as Balances)["usdt"] : BigNumber.from(0)}
          onChange={onUSDTAmountChange}
          disabled={disabled}
          placeholder="usdt Tokens"
          icon={() => icons.SVGs.usdt}
          label="USDT"
          decimals={6}
        />
      </div>
      <br />
      <div>
        <PositiveNumberInput value={weeks} fraction={false} onChange={onWeeksChange} disabled={disabled} placeholder={`Weeks (${MIN_WEEKS}-${MAX_WEEKS})`} />
        <Button disabled={disabled} onClick={onClickMax}>
          MAX
        </Button>
        <Button disabled={disabled || hasErrors || !amountsParsed} onClick={onClickStake}>
          Ape In 🐵
        </Button>
      </div>
      <div>
        <p>disabled: {disabled ? "true" : "false"}</p>
        <p>
          hasErrors: {hasErrors ? "true" : "false"} error:{error}
        </p>
        <p>!amountsParsed: {!amountsParsed ? "true" : "false"}</p>
        <p>uad:{UADAmount}</p>
        <p>dai:{DAIAmount}</p>
        <p>usdc:{USDCAmount}</p>
        <p>usdt:{USDTAmount}</p>
      </div>
      <div>{error && error.map((element, i) => <p key={i}>{element}</p>)}</div>
    </div>
  );
};

export default withLoadedContext(DepositStables);
