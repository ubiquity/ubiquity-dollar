import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";

import { ADDRESS } from "./index";

export function _renderTasklist() {
  return (
    <>
      <h1>tasklist</h1>
      <ol>
        <li>pending ugov reward</li>
        <li>bonding shares inputs for weeks and LP token amount</li>
        <li>link to crv.finance</li>
        <li>convert all wei into ether values</li>
      </ol>
    </>
  );
}
export function _depositBondingTokens(
  provider,
  account,
  setBondingTokenBalance
) {
  const missing = `missing input value for`;
  const bignumberErr = `can't parse BigNumber from`;

  let subject = `lp token amount`;

  const lpsAmount = document.getElementById("lpsAmount") as HTMLInputElement;
  const lpsAmountValue = lpsAmount?.value;
  if (!lpsAmountValue) {
    return alert(`${missing} ${subject}`);
  }
  if (BigNumber.isBigNumber(lpsAmountValue)) {
    return alert(`${bignumberErr} ${subject}`);
  }

  subject = `weeks lockup amount`;

  const weeks = document.getElementById("weeks") as HTMLInputElement;
  const weeksValue = weeks?.value;
  if (!weeksValue) {
    return alert(`${missing} ${subject}`);
  }
  if (BigNumber.isBigNumber(weeksValue)) {
    return alert(`${bignumberErr} ${subject}`);
  }

  return __depositBondingToken(
    BigNumber.from(lpsAmountValue),
    BigNumber.from(weeksValue),
    provider,
    account,
    setBondingTokenBalance
  );
}

export async function _connect(setProvider, setAccount): Promise<void> {
  if (!window.ethereum?.request) {
    alert("MetaMask is not installed!");
    return;
  }

  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });

  setProvider(provider);
  setAccount(accounts[0]);
}
export async function _getCurveTokenBalance(
  provider,
  account: string,
  setCurveTokenBalance
): Promise<void> {
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );
    const TOKEN_ADDR = await manager.curve3PoolTokenAddress();
    const token = ERC20__factory.connect(TOKEN_ADDR, provider);

    const rawBalance = await token.balanceOf(account);
    const decimals = await token.decimals();

    const balance = ethers.utils.formatUnits(rawBalance, decimals);
    setCurveTokenBalance(balance);
  }
}

export async function _getTokenBalance(
  provider,
  account: string,
  setTokenBalance
): Promise<void> {
  console.log("_getTokenBalance");
  // console.log("provider", provider);
  console.log("account", account);
  if (provider && account) {
    const uAD = UbiquityAlgorithmicDollar__factory.connect(
      ADDRESS.UAD,
      provider.getSigner()
    );
    console.log("ADDRESS.UAD", ADDRESS.UAD);
    //console.log("uAD", uAD);
    const rawBalance = await uAD.balanceOf(account);
    console.log("rawBalance", rawBalance);

    const decimals = await uAD.decimals();
    console.log("decimals", decimals);
    const balance = ethers.utils.formatUnits(rawBalance, decimals);
    console.log("balance", balance);
    setTokenBalance(balance);
  }
}
export async function _getLPTokenBalance(
  provider,
  account: string,
  setLPTokenBalance
): Promise<void> {
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );
    const TOKEN_ADDR = await manager.stableSwapMetaPoolAddress();

    const metapool = IMetaPool__factory.connect(TOKEN_ADDR, provider);
    const rawBalance = await metapool.balanceOf(account);
    const decimals = await metapool.decimals();

    const balance = ethers.utils.formatUnits(rawBalance, decimals);
    setLPTokenBalance(balance);
  }
}

async function __depositBondingToken(
  lpsAmount: ethers.BigNumber,
  weeks: ethers.BigNumber,
  provider,
  account: string,
  setBondingSharesBalance
) {
  if (provider && account) {
    const SIGNER = provider.getSigner();
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );
    const TOKEN_ADDR = await manager.stableSwapMetaPoolAddress();
    const metapool = IMetaPool__factory.connect(TOKEN_ADDR, SIGNER);
    const bonding = Bonding__factory.connect(ADDRESS.BONDING, SIGNER);
    const bondingShare = BondingShare__factory.connect(
      ADDRESS.BONDING_SHARE,
      SIGNER
    );
    // check approved amount
    // make sure to check balance spendable -- if (lpsAmount) is > spendable then ask approval again
    console.log(account);

    const allowance = await metapool.allowance(account, ADDRESS.BONDING);

    console.log("allowance", ethers.utils.formatEther(allowance));
    console.log("lpsAmount", ethers.utils.formatEther(lpsAmount));
    let approveTransaction;
    if (allowance.lt(lpsAmount)) {
      approveTransaction = await metapool.approve(ADDRESS.BONDING, lpsAmount);

      const approveWaiting = await approveTransaction.wait();
      console.log(
        `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(
          approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei"))
        )}`
      );
      const allowance2 = await metapool.allowance(account, ADDRESS.BONDING);
      console.log("allowance2", ethers.utils.formatEther(allowance2));
    }

    console.log({ lpsAmount, weeks });

    const depositWaiting = await bonding.deposit(lpsAmount, weeks);
    const waiting = await depositWaiting.wait();

    console.log(
      `deposit gas used with 100 gwei / gas:${ethers.utils.formatEther(
        waiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei"))
      )}`
    );

    /**
     *
     *
     */
    const addr = await SIGNER.getAddress();
    console.log({ addr });
    const ids = await bondingShare.holderTokens(addr);
    console.log(`
      ids of bonding shares
      length:${ids.length}
      0:${ids[0]} balance:${await bondingShare.balanceOf(addr, ids[0])} 
   
      `);

    const bondingSharesBalance = await bondingShare.balanceOf(addr, ids[0]);

    console.log({ ids, bondingSharesBalance });

    //
    let balance = BigNumber.from("0");
    if (ids.length > 1) {
      console.log(` 
      bondingShares ids   1:${ids[1]} balance:${await bondingShare.balanceOf(
        addr,
        ids[1]
      )}
   
      `);
      const balanceOfs = ids.map((id) => {
        return bondingShare.balanceOf(addr, id);
      });
      const balances = Promise.all(balanceOfs);
      balance = (await balances).reduce((prev, cur) => {
        return prev.add(cur);
      });
    } else {
      balance = bondingSharesBalance;
    }
    console.log(`
 balance:${balance.toString()} 
 `);
    setBondingSharesBalance(ethers.utils.formatEther(balance));
    /** */
    /*   const addr = await SIGNER.getAddress();
    console.log({ addr });
    const ids = await bondingShare.holderTokens(addr);
    console.log({ ids });

    const bondingSharesBalance = await bondingShare.balanceOf(addr, ids[0]);

    console.log({ ids, bondingSharesBalance }); */

    //
    // const decimals = await token.decimals();
    // const balance = ethers.utils.formatUnits(rawBalance, decimals);
    //setBondingTokenBalance(bondingSharesBalance.toString());
  } else {
    alert(`no provider and account found`);
  }
}

export function _renderControls({
  connect,
  account,
  provider,
  getTokenBalance,
  tokenBalance,
  getLPTokenBalance,
  tokenLPBalance,
  depositBondingTokens,
  tokenBondingSharesBalance,
  setCurveTokenBalance,
  getCurveTokenBalance,
  curveTokenBalance,
}) {
  return (
    <>
      <button onClick={connect}>Connect Wallet</button>
      <p>Account: {account}</p>
      <button onClick={getTokenBalance}>Get uAD Token Balance</button>
      <p>uAD Balance: {tokenBalance}</p>
      <button onClick={getLPTokenBalance}>Get LP Token Balance</button>
      <p>uAD3CRV-f Balance: {tokenLPBalance}</p>
      <button onClick={getCurveTokenBalance}>Get curve Token Balance</button>
      <p>3CRV Balance: {curveTokenBalance}</p>
      <input
        type="number"
        name="lpsAmount"
        id="lpsAmount"
        placeholder="uAD-3CRV LP Tokens"
      />
      <input type="number" name="weeks" id="weeks" placeholder="weeks" />
      <button onClick={depositBondingTokens}>
        Deposit Bonding Token Balance
      </button>
      <p>Token Balance: {tokenBondingSharesBalance}</p>
    </>
  );
}
