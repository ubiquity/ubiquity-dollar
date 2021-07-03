import { ethers, BigNumber } from "ethers";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import { BondingShare, BondingShare__factory } from "../src/types";

async function calculateBondingShareBalance(
  addr: string,
  bondingShare: BondingShare
) {
  //console.log({ addr });
  const ids = await bondingShare.holderTokens(addr);

  let bondingSharesBalance = BigNumber.from("0");
  if (ids && ids.length > 0) {
    bondingSharesBalance = await bondingShare.balanceOf(addr, ids[0]);
  }

  // console.log({ ids, bondingSharesBalance });

  //
  let balance = BigNumber.from("0");
  if (ids.length > 1) {
    /*  console.log(`
    bondingShares ids 1:${ids[1]} balance:${await bondingShare.balanceOf(
      addr,
      ids[1]
    )}

    `); */
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
async function _bondingShareBalance(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  provider: ethers.providers.Web3Provider | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>,
  setPercentage: Dispatch<SetStateAction<string | undefined>>
) {
  if (manager && provider) {
    const bondingShareAdr = await manager.bondingShareAddress();
    const bondingShare = BondingShare__factory.connect(
      bondingShareAdr,
      provider
    );

    if (bondingShare) {
      const rawBalance = await calculateBondingShareBalance(
        account,
        bondingShare
      );
      console.log("##rawBalance:", rawBalance.toString());
      if (balances) {
        if (!balances.bondingShares.eq(rawBalance))
          setBalances({ ...balances, bondingShares: rawBalance });
        const totalShareSupply = await bondingShare.totalSupply();

        const percentage = rawBalance
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

  const handleBalance = async () => {
    _bondingShareBalance(
      account ? account.address : "",
      manager,
      provider,
      balances,
      setBalances,
      setPercentage
    );
  };
  return (
    <>
      <div id="deposit-share-balance">
        <span>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
            <path fill="none" d="M0 0h20v20H0z" />
            <path d="M10 2s-6.5 5.16-6.5 9.5a6.5 6.5 0 1 0 13 0C16.5 7.16 10 2 10 2zm0 14.5c-2.76 0-5-2.24-5-5 0-2.47 3.1-5.8 5-7.53 1.9 1.73 5 5.05 5 7.53 0 2.76-2.24 5-5 5zm-2.97-4.57c.24 1.66 1.79 2.77 3.4 2.54a.5.5 0 0 1 .57.49c0 .28-.2.47-.42.5a4.013 4.013 0 0 1-4.54-3.39c-.04-.3.19-.57.5-.57.25 0 .46.18.49.43z" />
          </svg>
        </span>

        {/*
        <span>
          {balances ? `${parseInt(ethers.utils.formatEther(balances.bondingShares))}` : "0"}{" "}
          Bonding Shares
        </span> */}

        {bondingSharePercentage && (
          <>
            <span>{bondingSharePercentage}</span>
            <span> pool ownership.</span>
          </>
        )}
        {/* <button onClick={handleBalance}>Get Bonding Shares</button> */}
      </div>
    </>
  );
};

export default DepositShareBalance;
