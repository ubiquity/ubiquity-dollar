import simpleBondHandler from "./ubiquistick/SimpleBond";
import { CMDType, Deploy_Manager_Type } from "../shared";
import { createHandler } from "./create";
import ubiquiStickSaleHandler from "./ubiquistick/UbiquiStickSale";

const dollarPath = "src/dollar";
const corePath = "src/dollar/core";
const ubiquiStickPath = "src/ubiquistick";

const LPTokenName = "LP token";
const LPTokenSymbol = "LP";

const UARName = "Ubiquity Auto Redeem";
const UARSymbol = "uAR";

export const standardHandler = {
  SimpleBond: (args: CMDType) => {
    simpleBondHandler(args);
  },
  UbiquiStickSale: (args: CMDType) => {
    ubiquiStickSaleHandler(args);
  },
};

export const Deploy_Manager: Deploy_Manager_Type = {
  DirectGovernanceFarmer: (args: CMDType) => {
    const { manager, base3Pool, depositZap } = args;
    createHandler([manager, base3Pool, depositZap], args, `${dollarPath}/DirectGovernanceFarmer.sol:DirectGovernanceFarmer`);
  },
  Erc20Ubiquity: (args: CMDType) => {
    const { manager, name, symbol } = args;
    createHandler([manager, name, symbol], args, `${dollarPath}/ERC20Ubiquity.sol:ERC20Ubiquity`);
  },
  ERC1155Ubiquity: (args: CMDType) => {
    const { manager, uri } = args;
    createHandler([manager, uri], args, `${dollarPath}/ERC1155Ubiquity.sol:ERC1155Ubiquity`);
  },
  Staking: (args: CMDType) => {
    const { manager, stakingFormulasAddress, originals, lpBalances, weeks } = args;
    createHandler([manager, stakingFormulasAddress, originals, lpBalances, weeks], args, `${dollarPath}/Staking.sol:Staking`);
  },
  StakingFormulas: (args: CMDType) => {
    createHandler([], args, `${dollarPath}/StakingFormulas.sol:StakingFormulas`);
  },
  StakingShare: (args: CMDType) => {
    const { manager, uri } = args;
    createHandler([manager, uri], args, `${dollarPath}/StakingShare.sol:StakingShare`);
  },
  SushiSwapPool: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${dollarPath}/SushiSwapPool.sol:SushiSwapPool`);
  },
  UbiquityChef: (args: CMDType) => {
    const { manager, tos, amounts, stakingShareIDs } = args;
    createHandler([manager, tos, amounts, stakingShareIDs], args, `${dollarPath}/UbiquityChef.sol:UbiquityChef`);
  },
  UbiquityFormulas: (args: CMDType) => {
    createHandler([], args, `${dollarPath}/UbiquityFormulas.sol:UbiquityFormulas`);
  },
  CreditNFT: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/CreditNFT.sol:CreditNFT`);
  },
  CreditNFTManager: (args: CMDType) => {
    const { manager, creditNFTLengthBlocks } = args;
    createHandler([manager, creditNFTLengthBlocks], args, `${corePath}/CreditNFTManager.sol:CreditNFTManager`);
  },
  CreditNFTRedemptionCalculator: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/CreditNFTRedemptionCalculator.sol:CreditNFTRedemptionCalculator`);
  },
  CreditRedemptionCalculator: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/CreditRedemptionCalculator.sol:CreditRedemptionCalculator`);
  },
  DollarMintCalculator: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/DollarMintCalculator.sol:DollarMintCalculator`);
  },
  DollarMintExcess: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/DollarMintExcess.sol:DollarMintExcess`);
  },
  TWAPOracleDollar3pool: (args: CMDType) => {
    const { pool, dollarToken0, curve3CRVToken1 } = args;
    createHandler([pool, dollarToken0, curve3CRVToken1], args, `${corePath}/TWAPOracleDollar3pool.sol:TWAPOracleDollar3pool`);
  },
  UbiquityCreditToken: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/UbiquityCreditToken.sol:UbiquityCreditToken`);
  },
  UbiquityDollarManager: (args: CMDType) => {
    const { admin } = args;
    createHandler([admin], args, `${corePath}/UbiquityDollarManager.sol:UbiquityDollarManager`);
  },
  UbiquityDollarToken: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/UbiquityDollarToken.sol:UbiquityDollarToken`);
  },
  UbiquityGovernanceToken: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${corePath}/UbiquityGovernanceToken.sol:UbiquityGovernanceToken`);
  },
  LP: (args: CMDType) => {
    createHandler([LPTokenName, LPTokenSymbol], args, `${ubiquiStickPath}/LP.sol:LP`);
  },
  SimpleBond: (args: CMDType) => {
    standardHandler["SimpleBond"](args);
  },
  UAR: (args: CMDType) => {
    const { treasury } = args;
    createHandler([UARName, UARSymbol, treasury], args, `${ubiquiStickPath}/UAR.sol:UAR`);
  },
  UbiquiStick: (args: CMDType) => {
    //unfinished code
    //createHandler(...);
  },
  UbiquiStickSale: (args: CMDType) => {
    standardHandler["UbiquiStickSale"](args);
  },
};
