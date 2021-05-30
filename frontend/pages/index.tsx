import { FC, useState } from "react";
import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/artifacts/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../src/artifacts/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/artifacts/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/artifacts/types/factories/BondingShare__factory";

const ADDRESS = {
  UAD: "0x8b01F55C4D57d9678dB76b7082D9270d11616F78",
  METAPOOL: "0x152d13e62952a7c74c536bb3C8b7BD91853F076A",
  BONDING: "0x8a777acb51217cd8d8f5d05d05df334989ea976c",
  BONDING_SHARE: "0x07860015449240D2f20c63AF68b64cB0a2EA91Ee",
};

const Index: FC = (): JSX.Element => {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider>(),
    [account, setAccount] = useState<string>(),
    [tokenBalance, setTokenBalance] = useState<string>(),
    [tokenLPBalance, setLPTokenBalance] = useState<string>(),
    [tokenBondingBalance, setBondingTokenBalance] = useState<string>();

  return (
    <>
      {renderControls()}
      {renderTasklist()}
    </>
  );

  async function connect() {
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

  async function getTokenBalance() {
    if (provider && account) {
      const uAD = UbiquityAlgorithmicDollar__factory.connect(
        ADDRESS.UAD,
        provider.getSigner()
      );

      const rawBalance = await uAD.balanceOf(account);
      const decimals = await uAD.decimals();

      const balance = ethers.utils.formatUnits(rawBalance, decimals);
      setTokenBalance(balance);
    }
  }
  async function getLPTokenBalance() {
    if (provider && account) {
      const uAD = UbiquityAlgorithmicDollar__factory.connect(
        ADDRESS.METAPOOL,
        provider.getSigner()
      );

      const rawBalance = await uAD.balanceOf(account);
      const decimals = await uAD.decimals();

      const balance = ethers.utils.formatUnits(rawBalance, decimals);
      setLPTokenBalance(balance);
    }
  }

  async function depositBondingToken(
    lpsAmount: ethers.BigNumber,
    weeks: ethers.BigNumber
  ) {
    if (provider && account) {
      const SIGNER = provider.getSigner();

      const metapool = IMetaPool__factory.connect(ADDRESS.METAPOOL, SIGNER);
      const bonding = Bonding__factory.connect(ADDRESS.BONDING, SIGNER);
      const bondingShare = BondingShare__factory.connect(
        ADDRESS.BONDING_SHARE,
        SIGNER
      );
      // check approved amount

      // make sure to check balance spendable -- if (lpsAmount) is > spendable then ask approval again

      console.log(account);

      const allowable = (
        await metapool.allowance(account, ADDRESS.BONDING)
      ).toString();
      console.log({ allowable });
      const approveTransaction = await metapool.approve(
        ADDRESS.BONDING,
        lpsAmount
      );
      const approveWaiting = await approveTransaction.wait();

      console.log({ lpsAmount, weeks, approveWaiting });

      const depositWaiting = await bonding.deposit(lpsAmount, weeks);
      const waiting = await depositWaiting.wait();

      console.log({ waiting });

      console.log({ bondingShareContract: bondingShare });

      const addr = await SIGNER.getAddress();
      console.log({ addr });
      const ids = await bondingShare.holderTokens(addr);
      console.log({ ids });

      const bondingSharesBalance = await bondingShare.balanceOf(addr, ids[0]);

      console.log({ ids, bondingSharesBalance });

      //

      // const decimals = await token.decimals();
      // const balance = ethers.utils.formatUnits(rawBalance, decimals);
      setBondingTokenBalance(bondingSharesBalance.toString());
    } else {
      alert(`no provider and account found`);
    }
  }
  function depositBondingTokens() {
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

    return depositBondingToken(
      BigNumber.from(lpsAmountValue),
      BigNumber.from(weeksValue)
    );
  }

  function renderControls() {
    return (
      <>
        <button onClick={connect}>Connect Wallet</button>
        <p>Account: {account}</p>
        <button onClick={getTokenBalance}>Get Token Balance</button>
        <p>Token Balance: {tokenBalance}</p>
        <button onClick={getLPTokenBalance}>Get LP Token Balance</button>
        <p>Token Balance: {tokenLPBalance}</p>
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
        <p>Token Balance: {tokenBondingBalance}</p>
      </>
    );
  }
};

export default Index;

function renderTasklist() {
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
