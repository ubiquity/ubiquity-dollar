import { BigNumber, ethers } from "ethers";
import { useEffect, useState } from "react";

import { DebtCoupon, ERC1155Ubiquity } from "@/dollar-types";
import { ensureERC1155Allowance } from "@/lib/contracts-shortcuts";
import { formatEther } from "@/lib/format";
import { useBalances, useDeployedContracts, useManagerManaged, useSigner, useTransactionLogger, useWalletAddress } from "@/lib/hooks";
import { safeParseEther } from "@/lib/utils";
import { Button, PositiveNumberInput } from "@/ui";

const DebtCouponRedeem = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const deployedContracts = useDeployedContracts();
  const managedContracts = useManagerManaged();

  const [inputVal, setInputVal] = useState("");
  const [debtIds, setDebtIds] = useState<BigNumber[] | null>(null);
  const [debtBalances, setDebtBalances] = useState<BigNumber[]>([]);
  const [selectedDebtId, setSelectedDebtId] = useState(0);

  const setMax = () => {
    if (debtBalances[selectedDebtId]) {
      setInputVal(ethers.utils.formatEther(debtBalances[selectedDebtId]));
    }
  };

  useEffect(() => {
    if (managedContracts && walletAddress) {
      fetchDebts(walletAddress, managedContracts.debtCouponToken);
    }
  }, [managedContracts, walletAddress]);

  if (!walletAddress || !signer) return <span>Connect wallet</span>;
  if (!deployedContracts || !managedContracts || !debtIds) return <span>Loading...</span>;
  if (debtIds.length === 0) return <span>No credit coupons</span>;

  async function fetchDebts(address: string, contract: DebtCoupon) {
    const ids = await contract.holderTokens(address);
    const newBalances = await Promise.all(ids.map(async (id) => await contract.balanceOf(address, id)));
    setDebtIds(ids);
    setSelectedDebtId(0);
    setDebtBalances(newBalances);
  }

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    const selectedCouponBalance = debtBalances[selectedDebtId];
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(selectedCouponBalance) ? amount : null;
  };

  const handleRedeem = async () => {
    const amount = extractValidAmount(inputVal);
    if (amount) {
      doTransaction("Redeeming uCR-NFT...", async () => {
        setInputVal("");
        await redeemUdebtForUad(amount);
      });
    }
  };

  const redeemUdebtForUad = async (amount: BigNumber) => {
    const { debtCouponManager } = deployedContracts;
    const debtId = debtIds[selectedDebtId];
    if (
      debtId &&
      (await ensureERC1155Allowance(
        "uCR-NFT -> DebtCouponManager",
        (managedContracts.debtCouponToken as unknown) as ERC1155Ubiquity,
        signer,
        debtCouponManager.address
      ))
    ) {
      await (await debtCouponManager.connect(signer).redeemCoupons(debtId, amount)).wait();
      refreshBalances();
      fetchDebts(walletAddress, managedContracts.debtCouponToken);
    }
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  return (
    <div className="grid gap-4">
      <div className="flex">
        <select
          value={selectedDebtId}
          onChange={(ev) => setSelectedDebtId(parseInt(ev.target.value))}
          className="mr-2 block h-10 rounded-md border border-solid border-white/40 bg-white/10 p-2 outline-2 outline-accent/75 focus-visible:outline"
        >
          {debtIds.map((debtId, i) => (
            <option key={i} value={i}>
              {debtBalances[i] && `$${formatEther(debtBalances[i])}`}
            </option>
          ))}
        </select>
        <div className="relative">
          <PositiveNumberInput className="flex-grow pr-12" value={inputVal} onChange={setInputVal} placeholder="uCR-NFT Amount" />
          <div
            onClick={() => setMax()}
            className="absolute right-0 top-[50%] mr-2 flex  translate-y-[-50%] cursor-pointer items-center rounded-md border border-solid border-white bg-black/80 px-1 text-xs text-white hover:border-accent hover:text-accent hover:drop-shadow-accent"
          >
            MAX
          </div>
        </div>
      </div>
      <Button disabled={!submitEnabled} onClick={handleRedeem}>
        Redeem uCR-NFT for uAD
      </Button>
    </div>
  );
};

export default DebtCouponRedeem;
