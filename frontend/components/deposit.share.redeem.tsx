import { BigNumber, ethers } from "ethers";
import Image from "next/image";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import { Dropdown } from "react-dropdown-now";
import { InputValue, Option } from "react-dropdown-now/dist/types";
import {
  BondingShare__factory,
  Bonding__factory,
  UbiquityAlgorithmicDollarManager,
} from "../src/types";
import { EthAccount } from "../utils/types";
import { Balances, useConnectedContext } from "./context/connected";

export default DepositShareRedeem;

function DepositShareRedeem(): JSX.Element | null {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();
  const [debtIds, setDebtIds] = useState<InputValue[]>();
  const [blockNum, setBlockNumber] = useState<number>();
  useEffect(() => {
    // console.log("DepositShareRedeem  ");
    getBlockNumber(provider, setBlockNumber);
    _getDebtIds(
      account ? account.address : "",
      manager,
      provider,
      debtIds,
      setDebtIds,
      blockNum
    );
  });

  const [errMsg, setErrMsg] = useState<string>();
  const [isLoading, setIsLoading] = useState<boolean>();
  const [debtId, setDebtId] = useState<string>();
  const [debtAmount, setDebtAmount] = useState<string>();
  if (!account || !balances) {
    return null;
  }
  if (balances.uad.lte(BigNumber.from(0))) {
    return null;
  }
  const redeemBondingShare = redeemBondingShareCurry(
    provider,
    account,
    manager,
    balances
  );

  const handleRedeem = handleRedeemCurry(
    setErrMsg,
    setIsLoading,
    redeemBondingShare,
    debtId,
    setBalances
  );

  return (
    <>
      <div id="debt-coupon-redeem">
        <p>
          You will not receive your full principle from deposits until we finish
          Bonding V2. Read more{" "}
          <a href="https://dao.ubq.fi/28-june-2021" target="_blank">
            here
          </a>
          .
        </p>
        <Dropdown
          arrowClosed={<span className="arrow-closed" />}
          arrowOpen={<span className="arrow-open" />}
          placeholder="Select a deposit"
          className="dropdown"
          options={debtIds ?? []}
          onChange={(opt) => {
            if (opt && opt.id && opt.value) {
              setDebtId(opt.id.toString() as string);
              setDebtAmount(ethers.utils.formatEther(opt.value as BigNumber));
            }
          }}
        />

        <input
          type="number"
          name="bshareAmount"
          id="bshareAmount"
          placeholder="bonding share amount"
          value={debtAmount}
        />
        <button onClick={handleRedeem}>Withdraw LP Tokens</button>

        {isLoading && (
          <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
        )}
        <p>{errMsg}</p>
      </div>
    </>
  );
}

function handleRedeemCurry(
  setErrMsg: Dispatch<SetStateAction<string | undefined>>,
  setIsLoading: Dispatch<SetStateAction<boolean | undefined>>,
  redeemBondingShare: (
    debtId: string | undefined,
    amount: BigNumber,
    setBalances: Dispatch<SetStateAction<Balances | null>>
  ) => Promise<void>,
  debtId: string | undefined,
  setBalances: Dispatch<SetStateAction<Balances | null>>
) {
  return async () => {
    setErrMsg("");
    setIsLoading(true);
    const udebtAmount = document.getElementById(
      "bshareAmount"
    ) as HTMLInputElement;
    const udebtAmountValue = udebtAmount?.value;
    if (!udebtAmountValue) {
      // console.log("bshareAmount", udebtAmountValue);
      setErrMsg("Invalid withdraw amount");
    } else {
      const amount = ethers.utils.parseEther(udebtAmountValue);
      if (BigNumber.isBigNumber(amount)) {
        if (amount.gt(BigNumber.from(0))) {
          await redeemBondingShare(debtId, amount, setBalances);
        } else {
          setErrMsg("Amount should be greater than 0");
        }
      } else {
        setErrMsg("Invalid Amount");
        setIsLoading(false);
        return;
      }
    }
    setIsLoading(false);
  };
}

function redeemBondingShareCurry(
  provider: ethers.providers.Web3Provider | null,
  account: EthAccount,
  manager: UbiquityAlgorithmicDollarManager | null,
  balances: Balances
) {
  return async (
    debtId: string | undefined,
    amount: BigNumber,
    setBalances: Dispatch<SetStateAction<Balances | null>>
  ) => {
    // console.log("debtId", debtId);
    if (provider && account && manager && debtId) {
      await providerAccountManagerAndDebtId(
        manager,
        provider,
        account,
        amount,
        debtId,
        setBalances,
        balances
      );
      /*  const rawUARBalance = await debtCoupon.balanceOf(account.address);
      const rawUADBalance = await uAD.balanceOf(account.address);
      if (balances) {
        setBalances({ ...balances, uad: rawUADBalance, uar: rawUARBalance });
      } */
    }
  };
}

async function providerAccountManagerAndDebtId(
  manager: UbiquityAlgorithmicDollarManager,
  provider: ethers.providers.Web3Provider,
  account: EthAccount,
  amount: BigNumber,
  debtId: string,
  setBalances: Dispatch<SetStateAction<Balances | null>>,
  balances: Balances
) {
  const bondingShareAdr = await manager.bondingShareAddress();
  const bondingAdr = await manager.bondingContractAddress();
  const bondingShare = BondingShare__factory.connect(
    bondingShareAdr,
    provider.getSigner()
  );

  const isAllowed = await bondingShare.isApprovedForAll(
    account.address,
    bondingAdr
  );
  // console.log("isAllowed", isAllowed);
  if (!isAllowed) {
    // first approve
    const approveTransaction = await bondingShare.setApprovalForAll(
      bondingAdr,
      true
    );

    const approveWaiting = await approveTransaction.wait();
    console.log(
      `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(
        approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei"))
      )}`
    );
  }

  // const isAllowed2 = await bondingShare.isApprovedForAll(
  //   account.address,
  //   bondingAdr
  // );
  // console.log("isAllowed2", isAllowed2);
  const bonding = Bonding__factory.connect(bondingAdr, provider.getSigner());
  // console.log("amount", amount.toString());
  // console.log("debtId", BigNumber.from(debtId).toString());
  const redeemWaiting = await bonding.withdraw(amount, debtId);
  await redeemWaiting.wait();

  // fetch new uar and uad balance
  setBalances({
    ...balances,
    uad3crv: BigNumber.from(0),
    ubq: BigNumber.from(0),
    bondingShares: BigNumber.from(0),
  });
}

async function managerProviderAndBlockNumber(
  manager: UbiquityAlgorithmicDollarManager,
  provider: ethers.providers.Web3Provider,
  account: string,
  debtIds: InputValue[] | undefined,
  blockNum: number,
  setDebtIds: Dispatch<SetStateAction<InputValue[] | undefined>>
) {
  const bondingShare = BondingShare__factory.connect(
    await manager.bondingShareAddress(),
    provider.getSigner()
  );
  const idsRaw = await bondingShare.holderTokens(account);
  let ids = idsRaw;
  if (idsRaw.length > 1) {
    ids = [...idsRaw].sort((a: BigNumber, b: BigNumber) => {
      return a.lt(b) ? -1 : a.gt(b) ? 1 : 0;
    });
  }
  if (
    debtIds === undefined ||
    debtIds.length !== ids.length ||
    debtIds
      .map((cur, i) => ids[i].eq(BigNumber.from((cur as Option).id)))
      .filter((p) => p === false).length > 0
  ) {
    const sharesToRedeem: InputValue[] = [];
    for (let index = 0; index < ids.length; index++) {
      const id = ids[index];
      const bigBlockNum = BigNumber.from(blockNum);
      const balance = await bondingShare.balanceOf(account, id);
      const totalBondingShares = await bondingShare.totalSupply();
      const percent =
        parseInt(balance.toString()) / parseInt(totalBondingShares.toString());
      console.log({
        balance: balance.toString(),
        totalBondingShares: totalBondingShares.toString(),
        percent,
      });
      const humanReadableBondingShares = parseFloat(
        ethers.utils.formatEther(balance)
      ).toFixed(0);
      const label = `~${humanReadableBondingShares} bonding shares`;
      let shareOption: Option = {
        id: id.toString(),
        value: balance,
        label,
        className: "option",
      };
      if (id.gt(bigBlockNum)) {
        shareOption = {
          ...shareOption,
          className: "disable-option",
          disabled: true,
        };
      }
      sharesToRedeem.push(shareOption);
    }

    setDebtIds(sharesToRedeem);
  }
}

async function _getDebtIds(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  debtIds: InputValue[] | undefined,
  setDebtIds: Dispatch<SetStateAction<InputValue[] | undefined>>,
  blockNum: number | undefined
) {
  if (manager && provider && blockNum) {
    await managerProviderAndBlockNumber(
      manager,
      provider,
      account,
      debtIds,
      blockNum,
      setDebtIds
    );
  }
}
async function getBlockNumber(
  provider: ethers.providers.Web3Provider | null,
  setBlockNumber: Dispatch<SetStateAction<number | undefined>>
) {
  let blockNumber = 0;
  if (provider) {
    blockNumber = await provider?.getBlockNumber();
    setBlockNumber(blockNumber);
  }
}
