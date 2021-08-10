import { ethers, BigNumber } from "ethers";
import Image from "next/image";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import {
  BondingShareV2,
  MasterChefV2,
  MasterChefV2__factory,
  BondingShareV2__factory,
} from "../src/types";

// get all the shares (aka rights to get UBQ rewards) linked to bondingShares owned by an address
async function calculateBondingShareBalance(
  addr: string,
  bondingShare: BondingShareV2,
  masterchef: MasterChefV2
) {
  const ids = await bondingShare.holderTokens(addr);

  let bondingSharesBalance = BigNumber.from("0");

  if (ids && ids.length > 0) {
    bondingSharesBalance = await (
      await masterchef.getBondingShareInfo(ids[0])
    )[0];
  }

  let balance = BigNumber.from("0");
  if (ids.length > 1) {
    const balanceOfs = ids.map(async (id) => {
      const res = await masterchef.getBondingShareInfo(id);
      return res[0];
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
// get all the LP tokens  (aka  uAD3CRV-f) linked to bondingShares owned by an address
async function calculateBondingShareLPBalance(
  addr: string,
  bondingShare: BondingShareV2
) {
  const ids = await bondingShare.holderTokens(addr);
  let bondingSharesLPBalance = BigNumber.from("0");
  if (ids && ids.length > 0) {
    bondingSharesLPBalance = await (await bondingShare.getBond(ids[0]))
      .lpAmount;
  }

  let balance = BigNumber.from("0");
  if (ids.length > 1) {
    const balanceOfs = ids.map(async (id) => {
      const res = await bondingShare.getBond(id);
      return res.lpAmount;
    });
    const balances = Promise.all(balanceOfs);
    balance = (await balances).reduce((prev, cur) => {
      return prev.add(cur);
    });
  } else {
    balance = bondingSharesLPBalance;
  }

  return balance;
}
async function _bondingShareBalance(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>,
  setPercentage: Dispatch<SetStateAction<string | undefined>>
) {
  if (manager && provider) {
    const bondingShareAdr = await manager.bondingShareAddress();
    const bondingShare = BondingShareV2__factory.connect(
      bondingShareAdr,
      provider
    );
    const masterchefAdr = await manager.masterChefAddress();
    const masterchef = MasterChefV2__factory.connect(masterchefAdr, provider);
    if (bondingShare) {
      const rawShareBalance = await calculateBondingShareBalance(
        account,
        bondingShare,
        masterchef
      );
      console.log("##rawShare Balance:", rawShareBalance.toString());
      const rawShareLPBalance = await calculateBondingShareLPBalance(
        account,
        bondingShare
      );
      console.log("##rawShareLP Balance:", rawShareLPBalance.toString());
      if (balances) {
        if (!balances.bondingShares.eq(rawShareBalance))
          setBalances({ ...balances, bondingShares: rawShareBalance });
        if (!balances.bondingSharesLP.eq(rawShareLPBalance))
          setBalances({ ...balances, bondingSharesLP: rawShareLPBalance });
        const totalShareSupply = await masterchef.totalShares();
        if (totalShareSupply.gt(BigNumber.from(0))) {
          const percentage = rawShareBalance
            .mul(ethers.utils.parseEther("100"))
            .div(totalShareSupply);
          const percentageStr = ethers.utils.formatEther(percentage);

          setPercentage(
            `${percentageStr}%`
            // percentageStr.slice(0, percentageStr.indexOf(".") + 4) + "%"
          );
        }
      }
    }
  }
}

const DepositShareBalance = () => {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();

  const [bondingSharePercentage, setPercentage] = useState<string>();

  useEffect(() => {
    console.log("USEFFECTDEPOSITSHARE BALANCE");
    _bondingShareBalance(
      account ? account.address : "",
      manager,
      provider,
      balances,
      setBalances,
      setPercentage
    );
  }, [balances]);

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="deposit-share-balance">
        {balances && balances.bondingSharesLP && bondingSharePercentage ? (
          <>
            <span>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
                <path fill="none" d="M0 0h20v20H0z" />
                <path d="M10 2s-6.5 5.16-6.5 9.5a6.5 6.5 0 1 0 13 0C16.5 7.16 10 2 10 2zm0 14.5c-2.76 0-5-2.24-5-5 0-2.47 3.1-5.8 5-7.53 1.9 1.73 5 5.05 5 7.53 0 2.76-2.24 5-5 5zm-2.97-4.57c.24 1.66 1.79 2.77 3.4 2.54a.5.5 0 0 1 .57.49c0 .28-.2.47-.42.5a4.013 4.013 0 0 1-4.54-3.39c-.04-.3.19-.57.5-.57.25 0 .46.18.49.43z" />
              </svg>
            </span>
            <span>
              {parseInt(ethers.utils.formatEther(balances.bondingSharesLP))} LP
              locked in Bonding Shares{" "}
            </span>

            <div>
              <span>{bondingSharePercentage}</span>
              <span> pool ownership.</span>
            </div>
          </>
        ) : (
          <>
            <Image src="/loadanim.gif" alt="loading" width="64" height="64" />{" "}
            Loading LP locked in Bonding Shares...
          </>
        )}
      </div>
    </>
  );
};

export default DepositShareBalance;
