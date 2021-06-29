import { BigNumber, ethers } from "ethers";
import Image from "next/image";
import { Dispatch, SetStateAction, useState } from "react";
import {
  Bonding__factory, IMetaPool__factory,
  IUbiquityFormulas__factory
} from "../src/types";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { EthAccount } from "../utils/types";
import { Balances, useConnectedContext } from "./context/connected";
import DepositShareBalance from "./deposit.share.balance";

async function _allowAndDepositBondingToken(
  lpsAmount: ethers.BigNumber,
  weeks: ethers.BigNumber,
  provider: ethers.providers.Web3Provider | undefined,
  account: EthAccount,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  setErrMsg: Dispatch<SetStateAction<string | undefined>>
) {
  if (provider && account && manager) {
    // check approved amount
    // make sure to check balance spendable -- if (lpsAmount) is > spendable then ask approval again
    //console.log(account);
    const SIGNER = provider.getSigner();
    const BONDING_ADDR = await manager.bondingContractAddress();

    const metapool = IMetaPool__factory.connect(
      await manager.stableSwapMetaPoolAddress(),
      SIGNER
    );
    const bonding = Bonding__factory.connect(BONDING_ADDR, SIGNER);
    const allowance = await metapool.allowance(account.address, BONDING_ADDR);

    console.log("allowance", ethers.utils.formatEther(allowance));
    console.log("lpsAmount", ethers.utils.formatEther(lpsAmount));
    let approveTransaction;
    if (allowance.lt(lpsAmount)) {
      approveTransaction = await metapool.approve(BONDING_ADDR, lpsAmount);

      const approveWaiting = await approveTransaction.wait();
      console.log(
        `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(
          approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei"))
        )}`
      );
      const allowance2 = await metapool.allowance(
        account.address,
        BONDING_ADDR
      );
      console.log("allowance2", ethers.utils.formatEther(allowance2));
    }

    const depositWaiting = await bonding.deposit(lpsAmount, weeks);
    await depositWaiting.wait();
  } else {
    setErrMsg(`no provider and account found`);
  }
}

async function _depositBondingTokens(
  provider: ethers.providers.Web3Provider | undefined,
  account: EthAccount,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>,
  setErrMsg: Dispatch<SetStateAction<string | undefined>>,
  setIsLoading: Dispatch<SetStateAction<boolean | undefined>>
  // setPercentage: Dispatch<SetStateAction<string | undefined>>
) {
  setErrMsg("");
  setIsLoading(true);
  const missing = `missing input value for`;
  const bignumberErr = `can't parse BigNumber from`;

  let subject = `LP tokens amount`;

  const lpsAmount = document.getElementById("lpsAmount") as HTMLInputElement;
  const lpsAmountValue = lpsAmount?.value;
  if (!lpsAmountValue) {
    setErrMsg(`${missing} ${subject}`);
    setIsLoading(false);
    return;
  }
  if (BigNumber.isBigNumber(lpsAmountValue)) {
    setErrMsg(`${bignumberErr} ${subject}`);
    setIsLoading(false);
    return;
  }
  const amount = ethers.utils.parseEther(lpsAmountValue);
  if (!amount.gt(BigNumber.from(0))) {
    setErrMsg(`${subject} should be greater than 0`);
    setIsLoading(false);
    return;
  }

  subject = `weeks lockup amount`;

  const weeks = document.getElementById("weeks") as HTMLInputElement;
  const weeksValue = weeks?.value;
  if (!weeksValue) {
    setErrMsg(`${missing} ${subject}`);
    setIsLoading(false);
    return;
  }
  if (BigNumber.isBigNumber(weeksValue)) {
    setErrMsg(`${bignumberErr} ${subject}`);
    setIsLoading(false);
    return;
  }
  const weeksAmount = BigNumber.from(weeksValue);
  if (
    !weeksAmount.gt(BigNumber.from(3)) ||
    !weeksAmount.lte(BigNumber.from(208))
  ) {
    setErrMsg(`${subject} should be between 4 and 208`);
    setIsLoading(false);
    return;
  }

  await _allowAndDepositBondingToken(
    amount,
    BigNumber.from(weeksValue),
    provider,
    account,
    manager,
    setErrMsg
  );
  // trigger bondingShare calculation
  if (balances) {
    setBalances({ ...balances, bondingShares: BigNumber.from(0) });
  }
  setIsLoading(false);
}

async function _expectedShares(
  lpAmount: BigNumber,
  weeks: BigNumber,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  provider: ethers.providers.Web3Provider | undefined,
  setExpectedShares: Dispatch<SetStateAction<BigNumber | undefined>>
) {
  if (manager && provider) {
    const formulaAdr = await manager.formulasAddress();
    const SIGNER = provider.getSigner();
    const formula = IUbiquityFormulas__factory.connect(formulaAdr, SIGNER);
    const bondingAdr = await manager.bondingContractAddress();
    const bonding = Bonding__factory.connect(bondingAdr, SIGNER);
    const bondingDiscountMultiplier = await bonding.bondingDiscountMultiplier();
    const expectedShares = await formula.durationMultiply(
      lpAmount,
      weeks,
      bondingDiscountMultiplier
    );

    setExpectedShares(expectedShares);
  }
}

const DepositShare = () => {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();

  //const [bondingSharePercentage, setPercentage] = useState<string>();

  const [errMsg, setErrMsg] = useState<string>();
  const [isLoading, setIsLoading] = useState<boolean>();
  const [expectedShares, setExpectedShares] = useState<BigNumber>();
  if (!account) {
    return null;
  }

  const handleDeposit = async () => {
    console.log("loading", isLoading);
    _depositBondingTokens(
      provider,
      account,
      manager,
      balances,
      setBalances,
      setErrMsg,
      setIsLoading
      // setPercentage
    );
  };
  const handleInputWeeks = async () => {
    setErrMsg("");
    setIsLoading(true);
    const missing = `missing input value for`;
    const bignumberErr = `can't parse BigNumber from`;

    let subject = `LP tokens amount`;
    const lpsAmount = document.getElementById("lpsAmount") as HTMLInputElement;
    const lpsAmountValue = lpsAmount?.value;
    if (!lpsAmountValue) {
      setErrMsg(`${missing} ${subject}`);
      setIsLoading(false);
      return;
    }
    if (BigNumber.isBigNumber(lpsAmountValue)) {
      setErrMsg(`${bignumberErr} ${subject}`);
      setIsLoading(false);
      return;
    }
    const amount = ethers.utils.parseEther(lpsAmountValue);
    if (!amount.gt(BigNumber.from(0))) {
      setErrMsg(`${subject} should be greater than 0`);
      setIsLoading(false);
      return;
    }

    subject = `weeks lockup amount`;

    const weeks = document.getElementById("weeks") as HTMLInputElement;
    const weeksValue = weeks?.value;
    if (!weeksValue) {
      setErrMsg(`${missing} ${subject}`);
      setIsLoading(false);
      return;
    }
    if (BigNumber.isBigNumber(weeksValue)) {
      setErrMsg(`${bignumberErr} ${subject}`);
      setIsLoading(false);
      return;
    }
    const weeksAmount = BigNumber.from(weeksValue);
    if (
      !weeksAmount.gt(BigNumber.from(3)) ||
      !weeksAmount.lte(BigNumber.from(208))
    ) {
      setErrMsg(`${subject} should be between 4 and 208`);
      setIsLoading(false);
      return;
    }

    _expectedShares(amount, weeksAmount, manager, provider, setExpectedShares);
    setIsLoading(false);
  };
  return (
    <>
      <div id="deposit-share">
        <div>
          <input
            type="number"
            name="lpsAmount"
            id="lpsAmount"
            onInput={handleInputWeeks}
            placeholder="uAD-3CRV LP Tokens"
          />
          <input
            type="number"
            name="weeks"
            id="weeks"
            onInput={handleInputWeeks}
            placeholder="Weeks (4-208)"
            min="4"
            max="208"
          />
          <button  onClick={handleDeposit}>Stake LP Tokens</button>
          {isLoading && (
            <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
          )}
          <p>{errMsg}</p>

          {expectedShares && (
            <p>Expected bonding shares {ethers.utils.formatEther(expectedShares)}</p>
          )}

          <DepositShareBalance />
        </div>
      </div>
    </>
  );
};

export default DepositShare;
