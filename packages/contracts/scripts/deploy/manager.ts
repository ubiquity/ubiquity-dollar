import { CommandLineOption, DeployCallbackFn, deployments, Networks } from "../shared";
import { createHandler, getContract } from "./create";

const dollarPath = "src/dollar";
const corePath = "src/dollar/core";
const ubiquiStickPath = "src/ubiquistick";

const LPTokenName = "LP token";
const LPTokenSymbol = "LP";

const UARName = "Ubiquity Auto Redeem";
const UARSymbol = "uAR";

const simpleBondHandler = async (args: CommandLineOption) => {
  const { network, treasury } = args;
  let { vestingBlocks, testenv } = args;
  vestingBlocks = vestingBlocks ?? 32300; // about 5 days

  const chainId = Networks[network] ?? undefined;
  if (!chainId) {
    throw new Error(`Unsupported network: ${network} Please configure it out first`);
  }
  // If testenv is true, it means that the ownership is transferred in the deployment step
  // Must be careful when you deploy contracts to the mainnet.
  testenv = testenv ?? true;
  const { address: uARAddr, abi: uARAbi } = await deployments(chainId.toString(), "UAR");

  const { result, stderr } = await createHandler([uARAddr, vestingBlocks, treasury], args, `${ubiquiStickPath}/SimpleBond.sol:SimpleBond`);
  if (stderr || result === undefined) {
    return;
  }

  const simpleBondAddress = result.deployedTo;
  const { abi: sbAbi } = await deployments(chainId.toString(), "SimpleBond");
  const { abi: ubsAbi } = await deployments(chainId.toString(), "UbiquiStick");
  const simpleBondContract = await getContract(simpleBondAddress, sbAbi);
  console.log("Setting up the sticker...");
  let tx = await simpleBondContract.setSticker(ubsAbi);
  let receipt = await tx.wait();
  console.log("Setting up the sticker done!!!, hash: ", receipt.transactionHash);

  if (testenv) {
    console.log("Transferring the ownership of UAR to SimpleBond contract deployed recently...");
    const uARContract = await getContract(uARAddr, uARAbi);
    tx = await uARContract.transferOwnership(simpleBondAddress);
    console.log("Transferring ownership tx mined. tx: ", tx);
    receipt = await tx.wait();
    console.log("Transferring ownership done, hash: ", receipt.transactionHash);

    // TODO: Set allowance for SimpleBond to spend treasury money
  }
};

const ubiquiStickHandler = async (args: CommandLineOption) => {
  const { stderr, result } = await createHandler([], args, `${ubiquiStickPath}/UbiquiStick.sol:UbiquiStick`);
  if (stderr || result === undefined) {
    return;
  }
  // TODO: Do we need to set tokenURI during the deployment? For example, if we should have 10k tokens,
  // this part will definitely be an issue to consume lots of gas. General idea is to set baseURI and others are getting generated
  // from baseURI automatically. So it might be a way to have them as a forge script.
  //
  // prev source code:
  //
  // await ubiquiStick.connect(deployer).setTokenURI(0, tokenURIs.standardJson);
  // await ubiquiStick.connect(deployer).setTokenURI(1, tokenURIs.goldJson);
  // await ubiquiStick.connect(deployer).setTokenURI(2, tokenURIs.invisibleJson);
};

const ubiquiStickSaleHandler = async (args: CommandLineOption) => {
  const { network, treasury } = args;
  const chainId = Networks[network] ?? undefined;
  if (!chainId) {
    throw new Error(`Unsupported network: ${network} Please configure it out first`);
  }

  const { stderr, result } = await createHandler([], args, `${ubiquiStickPath}/UbiquiStickSale.sol:UbiquiStickSale`);
  if (stderr || result === undefined) {
    return;
  }

  const ubiquiStickSaleAddress = result.deployedTo;
  const ubiquiStickDeployments = await deployments(chainId.toString(), "UbiquiStick");

  const { address: ubdAddr, abi: ubdAbi } = ubiquiStickDeployments;
  const ubiquiStickContract = await getContract(ubdAddr, ubdAbi);
  console.log("Granting minter role to UbiquiStickSale contract...");
  let tx = await ubiquiStickContract.setMinter(ubiquiStickSaleAddress);
  let receipt = await tx.wait();
  console.log("Granting minter role to UbiquiStickSale contract done!!!, hash: ", receipt.transactionHash);

  console.log("Setting up funds address and token contract...");
  const { abi: ubsAbi } = await deployments(chainId.toString(), "UbiquiStickSale");
  const ubiquiStickSaleContract = await getContract(ubiquiStickSaleAddress, ubsAbi);
  tx = await ubiquiStickSaleContract.setFundsAddress(treasury);
  console.log("Setting funds address tx mined, tx: ", tx);
  receipt = await tx.wait();
  console.log("Setting funds address done, hash: ", receipt.transactionHash);

  tx = await ubiquiStickSaleContract.setTokenContract(ubdAddr);
  console.log("Setting token address tx mined, tx: ", tx);
  receipt = await tx.wait();
  console.log("Setting token address done, hash: ", receipt.transactionHash);
};

export const standardHandler = {
  SimpleBond: (args: CommandLineOption) => {
    simpleBondHandler(args);
  },
  UbiquiStick: (args: CommandLineOption) => {
    ubiquiStickHandler(args);
  },
  UbiquiStickSale: (args: CommandLineOption) => {
    ubiquiStickSaleHandler(args);
  },
};

export const Deploy_Manager: DeployCallbackFn = {
  DirectGovernanceFarmer: (args: CommandLineOption) => {
    const { manager, base3Pool, depositZap } = args;
    createHandler([manager, base3Pool, depositZap], args, `${dollarPath}/DirectGovernanceFarmer.sol:DirectGovernanceFarmer`);
  },
  Erc20Ubiquity: (args: CommandLineOption) => {
    const { manager, name, symbol } = args;
    createHandler([manager, name, symbol], args, `${dollarPath}/ERC20Ubiquity.sol:ERC20Ubiquity`);
  },
  ERC1155Ubiquity: (args: CommandLineOption) => {
    const { manager, uri } = args;
    createHandler([manager, uri], args, `${dollarPath}/ERC1155Ubiquity.sol:ERC1155Ubiquity`);
  },
  Staking: (args: CommandLineOption) => {
    const { manager, stakingFormulasAddress, originals, lpBalances, weeks } = args;
    createHandler([manager, stakingFormulasAddress, originals, lpBalances, weeks], args, `${dollarPath}/Staking.sol:Staking`);
  },
  StakingFormulas: (args: CommandLineOption) => {
    createHandler([], args, `${dollarPath}/StakingFormulas.sol:StakingFormulas`);
  },
  StakingShare: (args: CommandLineOption) => {
    const { manager, uri } = args;
    createHandler([manager, uri], args, `${dollarPath}/StakingShare.sol:StakingShare`);
  },
  SushiSwapPool: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${dollarPath}/SushiSwapPool.sol:SushiSwapPool`);
  },
  UbiquityChef: (args: CommandLineOption) => {
    const { manager, tos, amounts, stakingShareIDs } = args;
    createHandler([manager, tos, amounts, stakingShareIDs], args, `${dollarPath}/UbiquityChef.sol:UbiquityChef`);
  },
  UbiquityFormulas: (args: CommandLineOption) => {
    createHandler([], args, `${dollarPath}/UbiquityFormulas.sol:UbiquityFormulas`);
  },
  CreditNft: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/CreditNft.sol:CreditNft`);
  },
  CreditNftManager: (args: CommandLineOption) => {
    const { manager, creditNftLengthBlocks } = args;
    createHandler([manager, creditNftLengthBlocks], args, `${corePath}/CreditNftManager.sol:CreditNftManager`);
  },
  CreditNftRedemptionCalculator: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/CreditNftRedemptionCalculator.sol:CreditNftRedemptionCalculator`);
  },
  CreditRedemptionCalculator: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/CreditRedemptionCalculator.sol:CreditRedemptionCalculator`);
  },
  DollarMintCalculator: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/DollarMintCalculator.sol:DollarMintCalculator`);
  },
  DollarMintExcess: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/DollarMintExcess.sol:DollarMintExcess`);
  },
  TWAPOracleDollar3pool: (args: CommandLineOption) => {
    const { pool, dollarToken0, curve3CRVToken1 } = args;
    createHandler([pool, dollarToken0, curve3CRVToken1], args, `${corePath}/TWAPOracleDollar3pool.sol:TWAPOracleDollar3pool`);
  },
  UbiquityCreditToken: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/UbiquityCreditToken.sol:UbiquityCreditToken`);
  },
  UbiquityDollarManager: (args: CommandLineOption) => {
    const { admin } = args;
    createHandler([admin], args, `${corePath}/UbiquityDollarManager.sol:UbiquityDollarManager`);
  },
  UbiquityDollarToken: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/UbiquityDollarToken.sol:UbiquityDollarToken`);
  },
  UbiquityGovernanceToken: (args: CommandLineOption) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/UbiquityGovernanceToken.sol:UbiquityGovernanceToken`);
  },
  LP: (args: CommandLineOption) => {
    createHandler([LPTokenName, LPTokenSymbol], args, `${ubiquiStickPath}/LP.sol:LP`);
  },
  UAR: (args: CommandLineOption) => {
    const { treasury } = args;
    createHandler([UARName, UARSymbol, treasury], args, `${ubiquiStickPath}/UAR.sol:UAR`);
  },
  SimpleBond: (args: CommandLineOption) => {
    standardHandler["SimpleBond"](args);
  },
  UbiquiStick: (args: CommandLineOption) => {
    //unfinished code
    standardHandler["UbiquiStick"](args);
  },
  UbiquiStickSale: (args: CommandLineOption) => {
    standardHandler["UbiquiStickSale"](args);
  },
};
