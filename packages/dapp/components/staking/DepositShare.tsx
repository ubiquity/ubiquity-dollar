import { BigNumber, ethers } from "ethers";
import { constrainNumber } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/withLoadedContext";
import Button from "../ui/Button";
import PositiveNumberInput from "../ui/PositiveNumberInput";
import APR from "./APR";
import { useState } from "react";

const MIN_WEEKS = 1;
const MAX_WEEKS = 208;

type DepositShareProps = {
  onStake: ({ amount, weeks }: { amount: BigNumber; weeks: BigNumber }) => void;
  disabled: boolean;
  maxLp: BigNumber;
} & LoadedContext;

const DepositShare = ({ onStake, disabled, maxLp }: DepositShareProps) => {
  const [amount, setAmount] = useState("");
  const [weeks, setWeeks] = useState("");

  function validateAmount(): string | null {
    if (amount) {
      const amountBig = ethers.utils.parseEther(amount);
      if (amountBig.gt(maxLp)) return `You don't have enough uAD-3CRV tokens`;
    }
    return null;
  }

  const error = validateAmount();
  const hasErrors = !!error;

  const onWeeksChange = (inputVal: string) => {
    setWeeks(inputVal && constrainNumber(parseInt(inputVal), MIN_WEEKS, MAX_WEEKS).toString());
  };

  const onAmountChange = (inputVal: string) => {
    setAmount(inputVal);
  };

  const onClickStake = () => {
    onStake({ amount: ethers.utils.parseEther(amount), weeks: BigNumber.from(weeks) });
  };

  const onClickMax = () => {
    setAmount(ethers.utils.formatEther(maxLp));
    setWeeks(MAX_WEEKS.toString());
  };

  const noInputYet = !amount || !weeks;
  const amountParsed = parseFloat(amount);

  return (
    <div className="panel">
      <h2>Stake liquidity to receive UBQ</h2>
      <APR weeks={weeks} />
      <div style={{ display: "flex", flexDirection: "row", alignItems: "center" }}>
        <PositiveNumberInput value={amount} onChange={onAmountChange} disabled={disabled} placeholder="uAD-3CRV LP Tokens" />
        <PositiveNumberInput value={weeks} fraction={false} onChange={onWeeksChange} disabled={disabled} placeholder={`Weeks (${MIN_WEEKS}-${MAX_WEEKS})`} />
        <Button disabled={disabled} onClick={onClickMax}>
          MAX
        </Button>
        <Button disabled={disabled || hasErrors || noInputYet || !amountParsed} onClick={onClickStake}>
          Stake LP Tokens
        </Button>
      </div>
      <div>{error && <p>{error}</p>}</div>
    </div>
  );
};

export default withLoadedContext(DepositShare);
