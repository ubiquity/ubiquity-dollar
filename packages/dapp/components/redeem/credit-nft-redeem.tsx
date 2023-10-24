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

const CreditNftRedeem = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const protocolContracts = useProtocolContracts();

  const [inputVal, setInputVal] = useState("");
  const [creditIds, setCreditIds] = useState<BigNumber[] | null>(null);
  const [creditBalances, setCreditBalances] = useState<BigNumber[]>([]);
  const [selectedCreditId, setSelectedCreditId] = useState(0);

  const setMax = () => {
    if (creditBalances[selectedCreditId]) {
      setInputVal(ethers.utils.formatEther(creditBalances[selectedCreditId]));
    }
  };

  useEffectAsync(async () => {
    const contracts = await protocolContracts;
    if (contracts.creditNft && walletAddress) {
      fetchCredits(walletAddress, contracts.creditNft);
    }
  }, [walletAddress]);

  if (!walletAddress || !signer) return <span>Connect wallet</span>;
  if (!protocolContracts || !creditIds) return <span>· · ·</span>;
  if (creditIds.length === 0) return <span>No CREDIT-NFT Nfts</span>;

  async function fetchCredits(address: string, contract: Contract) {
    const ids = await contract.holderTokens(address);
    const newBalances = await Promise.all(ids.map(async (id: string) => await contract.balanceOf(address, id)));
    setCreditIds(ids);
    setSelectedCreditId(0);
    setCreditBalances(newBalances);
  }

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    const selectedNftBalance = creditBalances[selectedCreditId];
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(selectedNftBalance) ? amount : null;
  };

  const handleRedeem = async () => {
    const amount = extractValidAmount(inputVal);
    if (amount) {
      doTransaction("Redeeming CREDIT-NFT...", async () => {
        setInputVal("");
        await redeemCreditNftForDollar(amount);
      });
    }
  };

  const redeemCreditNftForDollar = async (amount: BigNumber) => {
    const contracts = await protocolContracts;
    const creditId = creditIds[selectedCreditId];
    if (contracts.creditNft && contracts.creditNftManagerFacet) {
      if (
        creditId &&
        (await ensureERC1155Allowance("CREDIT-NFT -> CreditNftManagerFacet", contracts.creditNft, signer, contracts.creditNftManagerFacet.address))
      ) {
        await (await contracts.creditNftManagerFacet.connect(signer).redeemCreditNft(creditId, amount)).wait();
        refreshBalances();
        fetchCredits(walletAddress, contracts.creditNft);
      }
    }
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  return (
    <div>
      <div>
        <select value={selectedCreditId} onChange={(ev) => setSelectedCreditId(parseInt(ev.target.value))}>
          {creditIds.map((creditId, i) => (
            <option key={i} value={i}>
              {creditBalances[i] && `$${formatEther(creditBalances[i])}`}
            </option>
          ))}
        </select>
        <div>
          <PositiveNumberInput value={inputVal} onChange={setInputVal} placeholder="CREDIT-NFT Amount" />
          <div onClick={() => setMax()}>MAX</div>
        </div>
      </div>
      <Button disabled={!submitEnabled} onClick={handleRedeem}>
        {/* cspell: disable-next-line */}
        Redeem CREDIT-NFT for DOLLAR
      </Button>
    </div>
  );
};

export default CreditNftRedeem;
