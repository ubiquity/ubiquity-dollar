import { BigNumber, ethers } from "ethers";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import { Dropdown } from "react-dropdown-now";
import Image from "next/image";
import {
  BondingShare__factory,
  Bonding__factory,
  UbiquityAlgorithmicDollarManager,
} from "../src/types";
import { ADDRESS } from "../pages";
import { InputValue, Option } from "react-dropdown-now/dist/types";

const _getDebtIds = async (
  account: string,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  provider: ethers.providers.Web3Provider | undefined,
  debtIds: InputValue[] | undefined,
  setDebtIds: Dispatch<SetStateAction<InputValue[] | undefined>>,
  blockNum: number | undefined
) => {
  if (manager && provider && blockNum) {
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
        const el = ids[index];
        const bigBlockNum = BigNumber.from(blockNum);

        const balance = await bondingShare.balanceOf(account, el);
        const label = `id:${el.toString()} amount:${ethers.utils.formatEther(
          balance
        )}`;
        let shareOption: Option = {
          id: el.toString(),
          value: balance,
          label,
          className: "option",
        };
        if (el.gt(bigBlockNum)) {
          shareOption = { ...shareOption, className: "disable-option" };
        }
        sharesToRedeem.push(shareOption);
      }

      setDebtIds(sharesToRedeem);
    }
  }
};

const getBlockNumber = async (
  provider: ethers.providers.Web3Provider | undefined,
  setBlockNumber: Dispatch<SetStateAction<number | undefined>>
) => {
  let blockNumber = 0;
  if (provider) {
    blockNumber = await provider?.getBlockNumber();
    setBlockNumber(blockNumber);
  }
};

const DepositShareRedeem = () => {
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
    console.log("DepositShareRedeem  ");
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
  const redeemBondingShare = async (
    debtId: string | undefined,
    amount: BigNumber,
    setBalances: Dispatch<SetStateAction<Balances | undefined>>
  ) => {
    console.log("debtId", debtId);
    if (provider && account && manager && debtId) {
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
      console.log("isAllowed", isAllowed);
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

      const isAllowed2 = await bondingShare.isApprovedForAll(
        account.address,
        bondingAdr
      );
      console.log("isAllowed2", isAllowed2);

      const bonding = Bonding__factory.connect(
        bondingAdr,
        provider.getSigner()
      );
      console.log("amount", amount.toString());
      console.log("debtId", BigNumber.from(debtId).toString());
      const redeemWaiting = await bonding.withdraw(amount, debtId);
      await redeemWaiting.wait();

      // fetch new uar and uad balance
      setBalances({
        ...balances,
        uad3crv: BigNumber.from(0),
        ubq: BigNumber.from(0),
        bondingShares: BigNumber.from(0),
      });
      /*  const rawUARBalance = await debtCoupon.balanceOf(account.address);
      const rawUADBalance = await uAD.balanceOf(account.address);
      if (balances) {
        setBalances({ ...balances, uad: rawUADBalance, uar: rawUARBalance });
      } */
    }
  };

  const handleRedeem = async () => {
    setErrMsg("");
    setIsLoading(true);
    const udebtAmount = document.getElementById(
      "bshareAmount"
    ) as HTMLInputElement;
    const udebtAmountValue = udebtAmount?.value;
    if (!udebtAmountValue) {
      console.log("bshareAmount", udebtAmountValue);
      setErrMsg("amount not valid");
    } else {
      const amount = ethers.utils.parseEther(udebtAmountValue);
      if (BigNumber.isBigNumber(amount)) {
        if (amount.gt(BigNumber.from(0))) {
          await redeemBondingShare(debtId, amount, setBalances);
        } else {
          setErrMsg("amount should be greater than 0");
        }
      } else {
        setErrMsg("amount not valid");
        setIsLoading(false);
        return;
      }
    }
    setIsLoading(false);
  };

  return (
    <>
      <div id="debt-coupon-redeem">
        <Dropdown
          arrowClosed={<span className="arrow-closed" />}
          arrowOpen={<span className="arrow-open" />}
          placeholder="Select an option"
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
        <button onClick={handleRedeem}>redeem Bonding Shares</button>

        {isLoading && (
          <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
        )}
        <p>{errMsg}</p>
      </div>
    </>
  );
};

export default DepositShareRedeem;
