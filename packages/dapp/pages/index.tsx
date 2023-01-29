import "@uniswap/widgets/fonts.css";
import { atom, useAtom } from "jotai";
import { withImmer } from "jotai-immer";

import useManagerManaged from "@/components/lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import DollarPrice from "@/components/redeem/DollarPrice";
import MigrateButton from "@/components/redeem/MigrateButton";
import WalletConnectionWall from "@/components/ui/WalletConnectionWall";

const primitiveAtom = atom(0);
const countAtom = withImmer(primitiveAtom);

export default function index() {
  // const [, setTwapPrice] = useAtom(countAtom);
  const [, setTwapInteger] = useAtom(countAtom);
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
    <>
      <WalletConnectionWall>
        <DollarPrice />
        <MigrateButton />
      </WalletConnectionWall>
    </>
  );
}
