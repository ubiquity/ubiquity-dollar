import { ethers, BigNumber } from "ethers";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import { Bonding, BondingShare, IMetaPool } from "../src/types";
import { EthAccount } from "../utils/types";
import Image from "next/image";

async function __depositBondingToken(
  lpsAmount: ethers.BigNumber,
  weeks: ethers.BigNumber,
  provider: ethers.providers.Web3Provider | undefined,
  account: EthAccount,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>,
  metapool: IMetaPool,
  bonding: Bonding,
  bondingShare: BondingShare,
  setErrMsg: Dispatch<SetStateAction<string | undefined>>
) {
  if (provider && account && manager) {
    // check approved amount
    // make sure to check balance spendable -- if (lpsAmount) is > spendable then ask approval again
    console.log(account);
    //const SIGNER = await provider.getSigner();
    const BONDING_ADDR = await manager.bondingContractAddress();

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

    const rawBalance = await calculateBondingShareBalance(
      account.address,
      bondingShare
    );
    if (balances) {
      if (!balances.bondingShares.eq(rawBalance))
        setBalances({ ...balances, bondingShares: rawBalance });
    }
  } else {
    setErrMsg(`no provider and account found`);
  }
}
async function calculateBondingShareBalance(
  addr: string,
  bondingShare: BondingShare
) {
  console.log({ addr });
  const ids = await bondingShare.holderTokens(addr);

  let bondingSharesBalance = BigNumber.from("0");
  if (ids && ids.length > 0) {
    bondingSharesBalance = await bondingShare.balanceOf(addr, ids[0]);
  }

  console.log({ ids, bondingSharesBalance });

  //
  let balance = BigNumber.from("0");
  if (ids.length > 1) {
    console.log(` 
    bondingShares ids 1:${ids[1]} balance:${await bondingShare.balanceOf(
      addr,
      ids[1]
    )}
 
    `);
    const balanceOfs = ids.map((id) => {
      return bondingShare.balanceOf(addr, id);
    });
    const balances = Promise.all(balanceOfs);
    balance = (await balances).reduce((prev, cur) => {
      return prev.add(cur);
    });
  } else {
    balance = bondingSharesBalance;
  }

  return balance;
}
async function _depositBondingTokens(
  provider: ethers.providers.Web3Provider | undefined,
  account: EthAccount,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>,
  metapool: IMetaPool,
  bonding: Bonding,
  bondingShare: BondingShare,
  setErrMsg: Dispatch<SetStateAction<string | undefined>>,
  setIsLoading: Dispatch<SetStateAction<boolean | undefined>>
) {
  setErrMsg("");
  setIsLoading(true);
  const missing = `missing input value for`;
  const bignumberErr = `can't parse BigNumber from`;

  let subject = `lp token amount`;

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
    !weeksAmount.gt(BigNumber.from(0)) ||
    !weeksAmount.lte(BigNumber.from(208))
  ) {
    setErrMsg(`${subject} should be between 1 and 208`);
    setIsLoading(false);
    return;
  }

  await __depositBondingToken(
    amount,
    BigNumber.from(weeksValue),
    provider,
    account,
    manager,
    balances,
    setBalances,
    metapool,
    bonding,
    bondingShare,
    setErrMsg
  );
  setIsLoading(false);
}
async function _bondingShareBalance(
  account: string,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>,
  bondingShare: BondingShare | undefined
) {
  if (bondingShare) {
    const rawBalance = await calculateBondingShareBalance(
      account,
      bondingShare
    );
    if (balances) {
      if (!balances.bondingShares.eq(rawBalance))
        setBalances({ ...balances, bondingShares: rawBalance });
    }
  }
}
const DepositShare = () => {
  const {
    account,
    manager,
    provider,
    metapool,
    bonding,
    bondingShare,
    balances,
    setBalances,
  } = useConnectedContext();
  useEffect(() => {
    _bondingShareBalance(
      account ? account.address : "",
      balances,
      setBalances,
      bondingShare
    );
  }, [balances]);

  const [errMsg, setErrMsg] = useState<string>();
  const [isLoading, setIsLoading] = useState<boolean>();
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
      metapool as IMetaPool,
      bonding as Bonding,
      bondingShare as BondingShare,
      setErrMsg,
      setIsLoading
    );
  };
  const handleBalance = async () => {
    _bondingShareBalance(
      account ? account.address : "",
      balances,
      setBalances,
      bondingShare
    );
  };
  return (
    <>
      <div className="row">
        <button onClick={handleBalance}>Get Bonding Shares</button>
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.bondingShares) : "0.0"}{" "}
          Bonding Shares
        </p>
      </div>
      <div className="row-wrap">
        <input
          type="number"
          name="lpsAmount"
          id="lpsAmount"
          placeholder="uAD-3CRV LP Tokens"
        />
        <input type="number" name="weeks" id="weeks" placeholder="weeks" />
        <button onClick={handleDeposit}>Deposit Bonding Token Balance</button>
        {isLoading && (
          <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
        )}
        <p className="error">{errMsg}</p>
      </div>
      <p>
        <a href="https://crv.finance/liquidity">
          Deposit to curve uAD-3CRV pool.
        </a>
        <br />
        Select pool Ubiquity Algorithmic Dollar (uAD3CRV-f-2){" "}
      </p>
    </>
  );
};

export default DepositShare;
