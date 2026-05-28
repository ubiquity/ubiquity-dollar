import { ethers } from "ethers";
import {
  getUbiquityManagerContract,
  // getERC20Contract,
  getCreditNftContract,
  getCreditNftManagerContract,
  getTWAPOracleContract,
  getDollarContract,
} from "@/components/utils/contracts";
import { Signer } from "ethers";
import { LOCAL_NODE_ADDRESS } from "@/components/lib/hooks/use-web-3";

const DEBUG = process.env.NEXT_PUBLIC_DEBUG || "";
const ON = "true";
const CHAIN_HEX = 0x7a69; // Anvil

export async function fetchData() {
  if (DEBUG === ON) {
    const JSON_RPC = new ethers.providers.JsonRpcProvider(LOCAL_NODE_ADDRESS);
    const provider = JSON_RPC;

    const LOCAL_CHAIN = provider.network?.chainId;
    const signer: Signer = provider.getSigner();

    const diamondAddress = "0xbe0efAbc83686a81903C1D4a2515f8111e53B5Cb";
    const diamondContract = getUbiquityManagerContract(diamondAddress, provider);

    // Check Address
    // This for debugging
    //Check Line 91
    //const UbiquityDollarToken = await getERC20Contract(diamondAddress, provider);

    const block = await provider.getBlockNumber();
    const RANDOM_WALLET = ethers.Wallet.createRandom().address;

    const ubiquityDollar = getDollarContract("0xF98F9083a9226b200dA8CbC4bfeCDAE58DA59889", provider);

    // NFTAddress
    const NFTMinter = ethers.Wallet.createRandom().address;
    const CreditNftFacet = getCreditNftContract(await diamondContract.creditNftAddress(), provider);
    const CreditNftManager = getCreditNftManagerContract(diamondAddress, provider);
    const TWAPOracle = getTWAPOracleContract(await diamondContract.twapOracleAddress(), provider);

    {
      try {
        // Default addresses after deploy
        console.log(diamondContract.address, "Diamond Address");
        console.log(await diamondContract.dollarTokenAddress(), "Dollar Token Address");
        console.log(await diamondContract.treasuryAddress(), "Treasury Address");
        console.log(await diamondContract.dollarMintCalculatorAddress(), "Dollar Mint Calc Address");

        // Credit NFT Minting and Balances
        console.log((await diamondContract.connect(signer).setCreditNftAddress("0xC39f62EC50748D6b05DC0dEf63943efF84E95f98")).hash);

        console.log(await diamondContract.creditNftAddress(), "Credit NFT Address");

        // Needs dynamism and more debugging but works mints and burns!
        console.log((await CreditNftFacet.connect(signer).mintCreditNft(signer.getAddress(), "1", 2000000 + 300)).hash);
        console.log((await CreditNftFacet.connect(signer).burnCreditNft(signer.getAddress(), 0, "1000000")).hash);

        console.log((await CreditNftFacet.totalSupply()).toBigInt(), "Credit NFT Total Supply");
        console.log((await CreditNftFacet.balanceOf(signer.getAddress(), "0")).toBigInt(), "Credit NFT Balance");
        console.log((await CreditNftFacet.holderTokens(signer.getAddress())).toString(), "Credit Holders");

        // Diamond Address
        console.log(await CreditNftFacet.getManager(), "Manager");

        console.log((await CreditNftManager.connect(signer).getCreditNftReturnedForDollars(signer.getAddress())).toBigInt(), "Credit NFT Returned Dollars");

        // Call CreditNft ManagerFacet
        console.log("Anvil Block Number", block);
        console.log("Connected to Chain ID", LOCAL_CHAIN);

        // triggers https://github.com/ubiquity/ubiquity-dollar/blob/f8ac092383b70ffbde4c22536025117babdf2c8f/packages/contracts/src/dollar/Diamond.sol#L41
        // but then it clogged the whole transactions, it's good to have it as a debug ref
        // console.log(
        //   await UbiquityDollarToken.connect(signer).decimals(),
        //   "Decimals"
        // );
      } catch (error) {
        console.log(error);
      }
    }

    if (LOCAL_CHAIN === CHAIN_HEX) {
      console.log(block, "Anvil Block");
    }

    // Bring to the front console
    console.log(await diamondContract.address, "Diamond Address");
    console.log(await diamondContract.treasuryAddress(), "Treasury Address");
    console.log(await diamondContract.dollarTokenAddress(), "Dollar Token");
    console.log(await diamondContract.creditNftAddress(), "Credit NFT Address");
    console.log(await diamondContract.twapOracleAddress(), "Twap Oracle Account");
    console.log(await diamondContract.governanceTokenAddress(), "Governance Token");
    console.log(await diamondContract.treasuryAddress(), "Treasury Address");

    console.log(NFTMinter, "NFTMinter Address");
    console.log(await signer.getAddress(), "msg.sender");
    console.log((await signer.getBalance()).toBigInt(), "msg.sender Balance");

    // Makes connection to set Dollar Token
    await diamondContract.connect(signer).setDollarTokenAddress(ubiquityDollar.address);
    console.log(await diamondContract.dollarTokenAddress(), "Dollar Token thru Diamond");
    console.log(ubiquityDollar.address, "Ubiquity....");

    console.log(await ubiquityDollar.deployed(), "Ubiquity deployed");

    // It will output token name at constructor time
    console.log(await ubiquityDollar.name());
    console.log(await ubiquityDollar.decimals(), "Ubiquity decimals");
    console.log((await ubiquityDollar.totalSupply()).toBigInt(), "Ubiquity total Supply");

    console.log((await ubiquityDollar.connect(signer).balanceOf(RANDOM_WALLET)).toBigInt(), "Random Wallet Balance");

    console.log("%c" + TWAPOracle.address, "color: yellow", "twap address");

    // Working
    console.log((await CreditNftManager.connect(signer).setExpiredCreditNftConversionRate(100)).hash, "Set Expired Credit NFT Conversion");
    console.log((await CreditNftManager.connect(signer).expiredCreditNftConversionRate()).toBigInt(), "Expired Credit NFT Conversion Rate");
    console.log((await CreditNftManager.connect(signer).setCreditNftLength(1000000000)).hash, "Set Credit NFT Length Blocks");
    console.log((await CreditNftManager.connect(signer).creditNftLengthBlocks()).toBigInt(), "Credit NFT Length Blocks");

    // Caller
    console.log(await signer.getAddress(), "Caller Address");
  }
}

fetchData();
export default fetchData;
