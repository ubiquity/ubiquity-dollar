import { ethers } from "ethers";
import { FC, useEffect, useState } from "react";
import "@uniswap/widgets/fonts.css";

import useManagerManaged from "@/components/lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import DollarPrice from "@/components/redeem/DollarPrice";
import MigrateButton from "@/components/redeem/MigrateButton";
import WalletConnectionWall from "@/components/ui/WalletConnectionWall";

const index: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address));
    }
  }, [managedContracts]);

  const [didMount, setDidMount] = useState(false);

  useEffect(() => {
    setDidMount(true);
  }, []);

  return (
    <div>
      {didMount && (
        <WalletConnectionWall>
          <DollarPrice />
          <MigrateButton />
        </WalletConnectionWall>
      )}
    </div>
  );
};

export default index;
