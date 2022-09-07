import { BigNumber } from "ethers";
import { useState } from "react";
import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
import useBalances from "../lib/hooks/useBalances";
import useEffectAsync from "../lib/hooks/useEffectAsync";
import useSigner from "../lib/hooks/useSigner";
import useWalletAddress from "../lib/hooks/useWalletAddress";

const BondingMigrate = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const managedContracts = useManagerManaged();
  const [, refreshBalances] = useBalances();

  const [errMsg, setErrMsg] = useState<string>();
  const [isLoading, setIsLoading] = useState<boolean>();
  const [migrateId, setMigrateId] = useState<BigNumber>();

  useEffectAsync(async () => {
    if (walletAddress && signer && managedContracts) {
      managedContracts.staking.connect(signer);
      setMigrateId(await managedContracts.staking.toMigrateId(walletAddress));
    }
  }, [walletAddress, signer]);

  if (!walletAddress || !migrateId || migrateId.eq(0)) {
    return null;
  }

  const handleMigration = async () => {
    if (managedContracts && migrateId) {
      setErrMsg("");
      setIsLoading(true);
      (async () => {
        managedContracts.staking;

        console.log("migrateID", migrateId);

        if (migrateId.gt(BigNumber.from(0))) {
          const migrateWaiting = await managedContracts.staking.migrate();
          await migrateWaiting.wait();
          refreshBalances();
          setMigrateId(undefined);
        } else {
          setErrMsg(`account not registered for migration`);
        }
        setIsLoading(false);
      })();
    }
  };

  return (
    <>
      <div id="bonding-migrate">
        <div>
          <button onClick={handleMigration}>Migrate</button>
          {isLoading && (
            <div>
              <div></div>
              <div></div>
              <div></div>
              <div></div>
            </div>
          )}
          {errMsg ? <p>{errMsg}</p> : null}
        </div>
      </div>
    </>
  );
};

export default BondingMigrate;
