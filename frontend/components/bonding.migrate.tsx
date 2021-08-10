import { BigNumber, ethers } from "ethers";
import Image from "next/image";
import { Dispatch, SetStateAction, useState, useEffect } from "react";
import { BondingV2__factory } from "../src/types";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { EthAccount } from "../utils/types";
import { Balances, useConnectedContext } from "./context/connected";

async function _migrate(
  provider: ethers.providers.Web3Provider | null,
  account: EthAccount,
  manager: UbiquityAlgorithmicDollarManager | null,
  setErrMsg: Dispatch<SetStateAction<string | undefined>>
) {
  if (provider && account && manager) {
    const SIGNER = provider.getSigner();
    const BONDING_ADDR = await manager.bondingContractAddress();

    const bonding = BondingV2__factory.connect(BONDING_ADDR, SIGNER);
    const migrateID = await bonding.toMigrateId(account.address);

    console.log("migrateID", migrateID);

    if (migrateID.gt(BigNumber.from(0))) {
      const migrateWaiting = await bonding.migrate();
      await migrateWaiting.wait();
    } else {
      setErrMsg(`account not registered for migration`);
    }
  }
}

async function _migrateBond(
  provider: ethers.providers.Web3Provider | null,
  account: EthAccount,
  manager: UbiquityAlgorithmicDollarManager | null,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>,
  setErrMsg: Dispatch<SetStateAction<string | undefined>>,
  setIsLoading: Dispatch<SetStateAction<boolean | undefined>>
  // setPercentage: Dispatch<SetStateAction<string | undefined>>
) {
  setErrMsg("");
  setIsLoading(true);

  await _migrate(provider, account, manager, setErrMsg);

  // trigger bondingShare calculation
  if (balances) {
    setBalances({ ...balances, bondingShares: BigNumber.from(0) });
  }
  setIsLoading(false);
}

const BondingMigrate = () => {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();

  const [errMsg, setErrMsg] = useState<string>();
  const [isLoading, setIsLoading] = useState<boolean>();
  const [migrateId, setMigrateId] = useState<BigNumber>();

  useEffect(() => {
    (async function () {
      if (provider && account && manager) {
        const SIGNER = provider.getSigner();
        const BONDING_ADDR = await manager.bondingContractAddress();
        const bonding = BondingV2__factory.connect(BONDING_ADDR, SIGNER);
        setMigrateId(await bonding.toMigrateId(account.address));
      }
    })();
  }, [account, manager, provider]);

  if (!account || !migrateId || migrateId.eq(0)) {
    return null;
  }

  const handleMigration = async () => {
    console.log("loading", isLoading);
    _migrateBond(
      provider,
      account,
      manager,
      balances,
      setBalances,
      setErrMsg,
      setIsLoading
      // setPercentage
    );
  };

  return (
    <>
      <div id="bonding-migrate">
        <div>
          <button onClick={handleMigration}>Migrate</button>
          {isLoading && (
            <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
          )}
          {errMsg ? <p>{errMsg}</p> : null}
        </div>
      </div>
    </>
  );
};

export default BondingMigrate;
