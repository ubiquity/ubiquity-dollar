import { BigNumber } from "ethers";
import { useState } from "react";
import { useBalances, useEffectAsync, useManagerManaged, useSigner, useWalletAddress } from "../lib/hooks";

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
      managedContracts.bonding.connect(signer);
      setMigrateId(await managedContracts.bonding.toMigrateId(walletAddress));
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
        managedContracts.bonding;

        console.log("migrateID", migrateId);

        if (migrateId.gt(BigNumber.from(0))) {
          const migrateWaiting = await managedContracts.bonding.migrate();
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
            <div className="lds-ring">
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
