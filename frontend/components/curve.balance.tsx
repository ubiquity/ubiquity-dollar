import { ethers } from "ethers";

import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect } from "react";

async function _getCurveTokenBalance(
  provider: ethers.providers.Web3Provider | undefined,
  account: string,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>
): Promise<void> {
  if (provider && account && manager) {
    const TOKEN_ADDR = await manager.curve3PoolTokenAddress();
    const token = ERC20__factory.connect(TOKEN_ADDR, provider);

    const rawBalance = await token.balanceOf(account);
    if (balances) {
      if (!balances.crv.eq(rawBalance))
        setBalances({ ...balances, crv: rawBalance });
    }
  }
}

const CurveBalance = () => {
  const {
    account,
    provider,
    manager,
    balances,
    setBalances,
  } = useConnectedContext();
  useEffect(() => {
    _getCurveTokenBalance(
      provider,
      account ? account.address : "",
      manager,
      balances,
      setBalances
    );
  }, [balances]);

  if (!account) {
    return null;
  }

  const handleClick = async () =>
    _getCurveTokenBalance(
      provider,
      account ? account.address : "",
      manager,
      balances,
      setBalances
    );
  return (
    <>
      <div id="curve-balance">
        <span>
          {balances ? ethers.utils.formatEther(balances.crv) : "0.0"} 3CRV
        </span>
        {/* <button onClick={handleClick}>Get curve Token Balance</button> */}
      </div>
    </>
  );
};

export default CurveBalance;
