import { FC, useState } from "react";
import { ethers, BigNumber } from "ethers";
import { UbiquityAlgorithmicDollar__factory } from "../contracts/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../contracts/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../contracts/types/factories/Bonding__factory";

const Index: FC = (): JSX.Element => {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider>();
  const [account, setAccount] = useState<string>();
  const [tokenBalance, setTokenBalance] = useState<string>();
  const [tokenLPBalance, setLPTokenBalance] = useState<string>();
  const [tokenBondingBalance, setBondingTokenBalance] = useState<string>();

  return (
    <>
      <button onClick={connect}>Connect</button>
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
      const TOKEN_ADDR = "0x8a777acb51217cd8d8f5d05d05df334989ea976c";
      const token = Bonding__factory.connect(TOKEN_ADDR, provider.getSigner());
      const metapool = IMetaPool__factory.connect(
        "0x152d13e62952a7c74c536bb3C8b7BD91853F076A",
        provider.getSigner()
      );
      const approveTransaction = metapool.approve(TOKEN_ADDR, lpsAmount);
      const approveWaiting = (await approveTransaction).wait();

      const depositWaiting = await token.deposit(lpsAmount, weeks);
      const waiting = await depositWaiting.wait();
      // const decimals = await token.decimals();
      // const balance = ethers.utils.formatUnits(rawBalance, decimals);
      // setLPTokenBalance(balance);
    } else {
      console.error(`no provider and account found`);
    }
  }
  function depositBondingTokens() {
    // () => {
    const lpsAmount = document.getElementById("lpsAmount") as HTMLInputElement;
    const lpsAmountValue = lpsAmount?.value;
    const weeks = document.getElementById("weeks") as HTMLInputElement;
    const weeksValue = weeks?.value;

    if (!lpsAmountValue || !weeksValue) {
      console.error(`missing input value for lp token amount or weeks`);
    } else {
      return depositBondingToken(
        BigNumber.from(lpsAmountValue),
        BigNumber.from(weeksValue)
      );
    }
    // }
  }
};

export default Index;

function renderTasklist() {
  return (
    <>
      <h1>tasklist</h1>
      <ol>
        <li>pending ugov reward</li>
        <li>bonding shares inputs</li>
        <li>for weeks and LP token amount</li>
        <li>link to crv.finance</li>
      </ol>
    </>
  );
}
