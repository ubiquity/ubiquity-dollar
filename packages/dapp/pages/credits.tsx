import UcrNftGenerator from "@/components/redeem/DebtCouponDeposit";
import MigrateButton from "@/components/redeem/MigrateButton";
import UcrNftRedeem from "@/components/redeem/UcrNftRedeem";
import UcrRedeem from "@/components/redeem/UcrRedeem";
import { atom, useAtom } from "jotai";
import { withImmer } from "jotai-immer";

import useManagerManaged from "@/components/lib/hooks/contracts/useManagerManaged";

import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import WalletConnectionWall from "@/components/ui/WalletConnectionWall";
const primitiveAtom = atom(0);
const countAtom = withImmer(primitiveAtom);

export default function PriceStabilization() {
  const [twapInteger, setTwapInteger] = useAtom(countAtom);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      const twapPrice = await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address);
      if (twapPrice) {
        const twapPriceInteger = Number(twapPrice) / 1e18;
        setTwapInteger(twapPriceInteger);
      }
    }
  }, [managedContracts]);

  return (
    <WalletConnectionWall>
      <div id="CreditOperations" data-twap={twapInteger}>
        <MigrateButton />
        <div id="MintUcr" className="panel">
          <h2>Generate Ubiquity Credit NFTs</h2>
          <aside>When TWAP is below peg</aside>
          <UcrNftGenerator />
        </div>
        <div id="RedeemUcr" className="panel">
          <h2>Redeem Ubiquity Credits</h2>
          <div>
            <UcrRedeem twapInteger={twapInteger} />
            <UcrNftRedeem />
          </div>
        </div>
      </div>
    </WalletConnectionWall>
  );
}
