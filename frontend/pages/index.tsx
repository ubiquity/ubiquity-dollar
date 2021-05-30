import { FC, useState } from "react";
import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/artifacts/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../src/artifacts/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/artifacts/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/artifacts/types/factories/BondingShare__factory";

// import "./styles/index.module.css"

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
      const TOKEN_ADDR = "0x8b01F55C4D57d9678dB76b7082D9270d11616F78";

      const token = UbiquityAlgorithmicDollar__factory.connect(
        TOKEN_ADDR,
        provider.getSigner()
      );

      const rawBalance = await token.balanceOf(account);
      const decimals = await token.decimals();

      const balance = ethers.utils.formatUnits(rawBalance, decimals);
      setTokenBalance(balance);
    }
  }
  async function getLPTokenBalance() {
    if (provider && account) {
      const TOKEN_ADDR = "0x152d13e62952a7c74c536bb3C8b7BD91853F076A";
      const token = UbiquityAlgorithmicDollar__factory.connect(
        TOKEN_ADDR,
        provider.getSigner()
      );

      const rawBalance = await token.balanceOf(account);
      const decimals = await token.decimals();

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

      const BONDING_ADDRESS = "0x8a777acb51217cd8d8f5d05d05df334989ea976c";
      const METAPOOL_ADDRESS = "0x152d13e62952a7c74c536bb3C8b7BD91853F076A";
      const BONDING_SHARE_ADDRESS =
        "0x07860015449240D2f20c63AF68b64cB0a2EA91Ee";
      // (method) Bonding__factory.connect(address: string, signerOrProvider: ethers.Signer | ethers.providers.Provider): Bonding
      const bondingContract = Bonding__factory.connect(BONDING_ADDRESS, SIGNER);
      // (method) IMetaPool__factory.connect(address: string, signerOrProvider: ethers.Signer | ethers.providers.Provider): IMetaPool
      const metapoolContract = IMetaPool__factory.connect(
        METAPOOL_ADDRESS,
        SIGNER
      );
      // (method) BondingShare__factory.connect(address: string, signerOrProvider: Signer | Provider): BondingShare

      // check approved amount

      // make sure to check balance spendable -- if (lpsAmount) is > spendable then ask approval again

      console.log(account);

      const allowable = (
        await metapoolContract.allowance(account, BONDING_ADDRESS)
      ).toString();
      console.log(allowable);
      const approveTransaction = await metapoolContract.approve(
        BONDING_ADDRESS,
        lpsAmount
      );
      const approveWaiting = await approveTransaction.wait();

      console.log(
        { lpsAmount, weeks }
        // await bondingContract.deposit()
      );
      const depositWaiting = await bondingContract.deposit(lpsAmount, weeks);
      const waiting = await depositWaiting.wait();

      //

      const bondingShareContract = BondingShare__factory.connect(
        BONDING_SHARE_ADDRESS,
        (SIGNER as any) as ethers.providers.Provider
      );

      console.log({ bondingShareContract });

      const addr = await SIGNER.getAddress();
      console.log({ addr });
      const ids = await bondingShareContract.holderTokens(addr);
      console.log({ ids });

      const bondingSharesBalance = await bondingShareContract.balanceOf(
        addr,
        ids[0]
      );

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
    // () => {
    const lpsAmount = document.getElementById("lpsAmount") as HTMLInputElement;
    const lpsAmountValue = lpsAmount?.value;
    const weeks = document.getElementById("weeks") as HTMLInputElement;
    const weeksValue = weeks?.value;

    if (!lpsAmountValue || !weeksValue) {
      alert(`missing input value for lp token amount or weeks`);
    } else {
      return depositBondingToken(
        BigNumber.from(lpsAmountValue),
        BigNumber.from(weeksValue)
      );
    }
    // }
  }

function renderControls() {
  return (<>
        <button onClick={connect}>Connect Wallet</button>
      <p>Account: {account}</p>
      <button onClick={getTokenBalance}>Get Token Balance</button>
      <p>Token Balance: {tokenBalance}</p>
      <button onClick={getLPTokenBalance}>Get LP Token Balance</button>
      <p>Token Balance: {tokenLPBalance}</p>
      <input
        type="text"
        name="lpsAmount"
        id="lpsAmount"
        placeholder="lpsAmount"
      />
      <input type="text" name="weeks" id="weeks" placeholder="weeks" />
      <button onClick={depositBondingTokens}>
        Deposit Bonding Token Balance
      </button>
      <p>Token Balance: {tokenBondingBalance}</p>
      </>)
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
