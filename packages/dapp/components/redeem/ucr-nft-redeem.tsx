import { BigNumber, ethers, Contract } from "ethers";
import { useState } from "react";

import { ensureERC1155Allowance } from "@/lib/contracts-shortcuts";
import { formatEther } from "@/lib/format";
import { safeParseEther } from "@/lib/utils";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useBalances from "../lib/hooks/use-balances";
import useSigner from "../lib/hooks/use-signer";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import useWalletAddress from "../lib/hooks/use-wallet-address";
import Button from "../ui/button";
import PositiveNumberInput from "../ui/positive-number-input";
import useEffectAsync from "../lib/hooks/use-effect-async";

const UcrNftRedeem = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const protocolContracts = useProtocolContracts();

  const [inputVal, setInputVal] = useState("");
  const [debtIds, setDebtIds] = useState<BigNumber[] | null>(null);
  const [debtBalances, setDebtBalances] = useState<BigNumber[]>([]);
  const [selectedDebtId, setSelectedDebtId] = useState(0);

  const setMax = () => {
    if (debtBalances[selectedDebtId]) {
      setInputVal(ethers.utils.formatEther(debtBalances[selectedDebtId]));
    }
  };

  useEffectAsync(async () => {
    const contracts = await protocolContracts;
    if (contracts && walletAddress) {
      fetchDebts(walletAddress, contracts.creditNft!);
    }
  }, [protocolContracts, walletAddress]);

  if (!walletAddress || !signer) return <span>Connect wallet</span>;
  if (!protocolContracts || !debtIds) return <span>· · ·</span>;
  if (debtIds.length === 0) return <span>No uCR-NFT coupons</span>;

  async function fetchDebts(address: string, contract: Contract) {
    const ids = await contract.holderTokens(address);
    const newBalances = await Promise.all(ids.map(async (id: string) => await contract.balanceOf(address, id)));
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
        await redeemUcrNftForUad(amount);
      });
    }
  };

  const redeemUcrNftForUad = async (amount: BigNumber) => {
    const contracts = await protocolContracts;
    const debtId = debtIds[selectedDebtId];
    if (debtId && (await ensureERC1155Allowance("uCR-NFT -> CreditNftManagerFacet", contracts.creditNft!, signer, contracts.creditNftManagerFacet!.address))) {
      await (await contracts.creditNftManagerFacet!.connect(signer).redeemCreditNft(debtId, amount)).wait();
      refreshBalances();
      fetchDebts(walletAddress, contracts.creditNft!);
    }
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  return (
    <div>
      <div>
        <select value={selectedDebtId} onChange={(ev) => setSelectedDebtId(parseInt(ev.target.value))}>
          {debtIds.map((debtId, i) => (
            <option key={i} value={i}>
              {debtBalances[i] && `$${formatEther(debtBalances[i])}`}
            </option>
          ))}
        </select>
        <div>
          <PositiveNumberInput value={inputVal} onChange={setInputVal} placeholder="uCR-NFT Amount" />
          <div onClick={() => setMax()}>MAX</div>
        </div>
      </div>
      <Button disabled={!submitEnabled} onClick={handleRedeem}>
        {/* cspell: disable-next-line */}
        Redeem uCR-NFT for uAD
      </Button>
    </div>
  );
};

export default UcrNftRedeem;
