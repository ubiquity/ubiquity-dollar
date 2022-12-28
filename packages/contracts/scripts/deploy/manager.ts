import simpleBondHandler from "./ubiquistick/SimpleBond";
import { CMDType, Deploy_Manager_Type } from "../shared";
import { createHandler } from "./create";
import ubiquiStickSaleHandler from "./ubiquistick/UbiquiStickSale";

const dollarPath = "src/dollar";
const cPath = "src/dollar/core";
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
    createHandler([manager, base3Pool, depositZap], args, `${dPath}/DirectGovernanceFarmer.sol:DirectGovernanceFarmer`);
  },
  Erc20Ubiquity: (args: CMDType) => {
    const { manager, name, symbol } = args;
    createHandler([manager, name, symbol], args, `${dPath}/ERC20Ubiquity.sol:ERC20Ubiquity`);
  },
  ERC1155Ubiquity: (args: CMDType) => {
    const { manager, uri } = args;
    createHandler([manager, uri], args, `${dPath}/ERC1155Ubiquity.sol:ERC1155Ubiquity`);
  },
  Staking: (args: CMDType) => {
    const { manager, stakingFormulasAddress, originals, lpBalances, weeks } = args;
    createHandler([manager, stakingFormulasAddress, originals, lpBalances, weeks], args, `${dPath}/Staking.sol:Staking`);
  },
  StakingFormulas: (args: CMDType) => {
    createHandler([], args, `${dPath}/StakingFormulas.sol:StakingFormulas`);
  },
  StakingShare: (args: CMDType) => {
    const { manager, uri } = args;
    createHandler([manager, uri], args, `${dPath}/StakingShare.sol:StakingShare`);
  },
  SushiSwapPool: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${dPath}/SushiSwapPool.sol:SushiSwapPool`);
  },
  UbiquityChef: (args: CMDType) => {
    const { manager, tos, amounts, stakingShareIDs } = args;
    createHandler([manager, tos, amounts, stakingShareIDs], args, `${dPath}/UbiquityChef.sol:UbiquityChef`);
  },
  UbiquityFormulas: (args: CMDType) => {
    createHandler([], args, `${dPath}/UbiquityFormulas.sol:UbiquityFormulas`);
  },
  CreditNFT: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/CreditNFT.sol:CreditNFT`);
  },
  CreditNFTManager: (args: CMDType) => {
    const { manager, creditNFTLengthBlocks } = args;
    createHandler([manager, creditNFTLengthBlocks], args, `${cPath}/CreditNFTManager.sol:CreditNFTManager`);
  },
  CreditNFTRedemptionCalculator: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/CreditNFTRedemptionCalculator.sol:CreditNFTRedemptionCalculator`);
  },
  CreditRedemptionCalculator: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/CreditRedemptionCalculator.sol:CreditRedemptionCalculator`);
  },
  DollarMintCalculator: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/DollarMintCalculator.sol:DollarMintCalculator`);
  },
  DollarMintExcess: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/DollarMintExcess.sol:DollarMintExcess`);
  },
  TWAPOracleDollar3pool: (args: CMDType) => {
    const { pool, dollarToken0, curve3CRVToken1 } = args;
    createHandler([pool, dollarToken0, curve3CRVToken1], args, `${cPath}/TWAPOracleDollar3pool.sol:TWAPOracleDollar3pool`);
  },
  UbiquityCreditToken: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/UbiquityCreditToken.sol:UbiquityCreditToken`);
  },
  UbiquityDollarManager: (args: CMDType) => {
    const { admin } = args;
    createHandler([admin], args, `${cPath}/UbiquityDollarManager.sol:UbiquityDollarManager`);
  },
  UbiquityDollarToken: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/UbiquityDollarToken.sol:UbiquityDollarToken`);
  },
  UbiquityGovernanceToken: (args: CMDType) => {
    const { manager } = args;
    createHandler([manager], args, `${cPath}/UbiquityGovernanceToken.sol:UbiquityGovernanceToken`);
  },
  LP: (args: CMDType) => {
    createHandler([LPTokenName, LPTokenSymbol], args, `${uPath}/LP.sol:LP`);
  },
  SimpleBond: (args: CMDType) => {
    standardHandler["SimpleBond"](args);
  },
  UAR: (args: CMDType) => {
    const { treasury } = args;
    createHandler([UARName, UARSymbol, treasury], args, `${uPath}/UAR.sol:UAR`);
  },
  UbiquiStick: (args: CMDType) => {
    //unfinished code
    //createHandler(...);
  },
  UbiquiStickSale: (args: CMDType) => {
    standardHandler["UbiquiStickSale"](args);
  },
};
