import { OptionDefinition } from "command-line-args";

import { DeployFuncCallback } from "../shared";
import creditNFTFunc, { optionDefinitions as creditNFTOptions } from "./dollar/core/CreditNFT";
import creditNFTManagerFunc, { optionDefinitions as creditNFTManagerOptions } from "./dollar/core/CreditNFTManager";
import creditNFTRedemptionCalculatorFunc, { optionDefinitions as creditNFTRedemptionCalculatorOptions } from "./dollar/core/CreditNFTRedemptionCalculator";
import creditRedemptionCalculatorFunc, { optionDefinitions as creditRedemptionCalculatorOptions } from "./dollar/core/CreditRedemptionCalculator";
import dollarMintCalculatorFunc, { optionDefinitions as dollarMintCalculatorOptions } from "./dollar/core/DollarMintCalculator";
import dollarMintExcessFunc, { optionDefinitions as dollarMintExcessOptions } from "./dollar/core/DollarMintExcess";
import twapOracleDollar3poolFunc, { optionDefinitions as twapOracleDollar3poolOptions } from "./dollar/core/TWAPOracleDollar3pool";
import ubiquityCreditTokenFunc, { optionDefinitions as ubiquityCreditTokenOptions } from "./dollar/core/UbiquityCreditToken";
import ubiquityDollarManagerFunc, { optionDefinitions as ubiquityDollarManagerOptions } from "./dollar/core/UbiquityDollarManager";
import ubiquityDollarTokenFunc, { optionDefinitions as ubiquityDollarTokenOptions } from "./dollar/core/UbiquityDollarToken";
import ubiquityGovernanceTokenFunc, { optionDefinitions as ubiquityGovernanceTokenOptions } from "./dollar/core/UbiquityGovernanceToken";

import directGovernanceFarmerFunc, { optionDefinitions as directGovernanceFarmerOptions } from "./dollar/DirectGovernanceFarmer";
import erc20UbiquityFunc, { optionDefinitions as erc20UbiquityOptions } from "./dollar/ERC20Ubiquity";
import erc1155UbiquityFunc, { optionDefinitions as erc1155UbiquityOptions } from "./dollar/ERC1155Ubiquity";
import stakingFunc, { optionDefinitions as stakingOptions } from "./dollar/Staking";
import stakingFormulasFunc, { optionDefinitions as stakingFormulasOptions } from "./dollar/StakingFormulas";
import stakingShareFunc, { optionDefinitions as stakingShareOptions } from "./dollar/StakingShare";
import ubiquityChefFunc, { optionDefinitions as ubiquityChefOptions } from "./dollar/UbiquityChef";
import ubiquityFormulasFunc, { optionDefinitions as ubiquityFormulasOptions } from "./dollar/UbiquityFormulas";
import sushiSwapPoolFunc, { optionDefinitions as sushiSwapPoolOptions } from "./dollar/SushiSwapPool";
/* 
import uARForDollarsCalculatorFunc, { optionDefinitions as uARForDollarsCalculatorOptions } from "./dollar/UARForDollarsCalculator";
import ubiquityAlgorithmicDollarFunc, { optionDefinitions as ubiquityAlgorithmDollarOptions } from "./dollar/UbiquityAlgorithmicDollar";
import ubiquityAutoRedeemFunc, { optionDefinitions as ubiquityAutoRedeemOptions } from "./dollar/UbiquityAutoRedeem";
 */
import ubiquiStickFunc, { optionDefinitions as ubiquiStickOptions } from "./ubiquistick/UbiquiStick";
import ubiquiStickSaleFunc, { optionDefinitions as ubiquiStickSaleOptions } from "./ubiquistick/UbiquiStickSale";
import uARFunc, { optionDefinitions as uAROptions } from "./ubiquistick/UAR";
import lpFunc, { optionDefinitions as lpOptions } from "./ubiquistick/LP";
import simpleBondFunc, { optionDefinitions as simpleBondOptions } from "./ubiquistick/SimpleBond";

export const DEPLOY_FUNCS: Record<string, { handler: DeployFuncCallback; options: OptionDefinition[] }> = {
  DirectGovernanceFarmer: {
    handler: directGovernanceFarmerFunc,
    options: directGovernanceFarmerOptions,
  },
  Erc20Ubiquity: {
    handler: erc20UbiquityFunc,
    options: erc20UbiquityOptions,
  },
  ERC1155Ubiquity: {
    handler: erc1155UbiquityFunc,
    options: erc1155UbiquityOptions,
  },
  Staking: {
    handler: stakingFunc,
    options: stakingOptions,
  },
  StakingFormulas: {
    handler: stakingFormulasFunc,
    options: stakingFormulasOptions,
  },
  StakingShare: {
    handler: stakingShareFunc,
    options: stakingShareOptions,
  },
  ubiquityChef: {
    handler: ubiquityChefFunc,
    options: ubiquityChefOptions,
  },
  UbiquityFormulas: {
    handler: ubiquityFormulasFunc,
    options: ubiquityFormulasOptions,
  },
  SushiSwapPool: {
    handler: sushiSwapPoolFunc,
    options: sushiSwapPoolOptions,
  },

  CreditNFT: {
    handler: creditNFTFunc,
    options: creditNFTOptions,
  },
  CreditNFTManager: {
    handler: creditNFTManagerFunc,
    options: creditNFTManagerOptions,
  },
  CreditRedemptionCalculator: {
    handler: creditRedemptionCalculatorFunc,
    options: creditRedemptionCalculatorOptions,
  },
  CreditNFTRedemptionCalculator: {
    handler: creditNFTRedemptionCalculatorFunc,
    options: creditNFTRedemptionCalculatorOptions,
  },
  DollarMintCalculator: {
    handler: dollarMintCalculatorFunc,
    options: dollarMintCalculatorOptions,
  },
  DollarMintExcess: {
    handler: dollarMintExcessFunc,
    options: dollarMintExcessOptions,
  },
  TWAPOracleDollar3pool: {
    handler: twapOracleDollar3poolFunc,
    options: twapOracleDollar3poolOptions,
  },
  UbiquityCreditToken: {
    handler: ubiquityCreditTokenFunc,
    options: ubiquityCreditTokenOptions,
  },
  UbiquityDollarManager: {
    handler: ubiquityDollarManagerFunc,
    options: ubiquityDollarManagerOptions,
  },
  UbiquityDollarToken: {
    handler: ubiquityDollarTokenFunc,
    options: ubiquityDollarTokenOptions,
  },
  UbiquityGovernanceToken: {
    handler: ubiquityGovernanceTokenFunc,
    options: ubiquityGovernanceTokenOptions,
  },
  UbiquiStick: {
    handler: ubiquiStickFunc,
    options: ubiquiStickOptions,
  },
  UbiquiStickSale: {
    handler: ubiquiStickSaleFunc,
    options: ubiquiStickSaleOptions,
  },
  UAR: {
    handler: uARFunc,
    options: uAROptions,
  },
  LP: {
    handler: lpFunc,
    options: lpOptions,
  },
  SimpleBond: {
    handler: simpleBondFunc,
    options: simpleBondOptions,
  },
};
