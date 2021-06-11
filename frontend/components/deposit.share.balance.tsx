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
      if (balances) {
        if (!balances.bondingShares.eq(rawBalance))
          setBalances({ ...balances, bondingShares: rawBalance });
        const totalShareSupply = await bondingShare.totalSupply();

        const percentage = rawBalance
          .mul(ethers.utils.parseEther("100"))
          .div(totalShareSupply);
        const percentageStr = ethers.utils.formatEther(percentage);

        setPercentage(
          percentageStr.slice(0, percentageStr.indexOf(".") + 6) + " %"
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
      <div className="row">
        <button onClick={handleBalance}>Get Bonding Shares</button>
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.bondingShares) : "0.0"}{" "}
          Bonding Shares
        </p>
      </div>
      {bondingSharePercentage && (
        <p className="info">
          you share represents {bondingSharePercentage} of the pool
        </p>
      )}
    </>
  );
};

export default DepositShareBalance;
