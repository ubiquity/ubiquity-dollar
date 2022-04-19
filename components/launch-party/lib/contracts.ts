import { ERC20 } from "../../../contracts/dollar/artifacts/types";
import {
  TheUbiquityStickSale__factory,
  SimpleBond__factory,
  SimpleBond,
  TheUbiquityStickSale,
  TheUbiquityStick,
  TheUbiquityStick__factory,
} from "../../../contracts/ubiquistick/types";
import { ChainlinkPriceFeed, ChainlinkPriceFeed__factory } from "../../../fixtures/abi/types";
import deployedAddresses from "../../../fixtures/contracts-addresses/ubiquistick.json";

type Addresses = {
  TheUbiquityStick: string;
  TheUbiquityStickSale: string;
  SimpleBond: string;
  chainLinkEthUsd: string;
};

const externalAddresses = { chainLinkEthUsd: "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419" };

const castedDeployedAddress = (deployedAddresses as unknown) as { [key: string]: Addresses };

for (const key in castedDeployedAddress) {
  castedDeployedAddress[key] = { ...castedDeployedAddress[key], ...externalAddresses };
}

export const addresses = castedDeployedAddress;

export type Contracts = {
  ubiquiStick: TheUbiquityStick;
  ubiquiStickSale: TheUbiquityStickSale;
  simpleBond: SimpleBond;
  rewardToken: ERC20;
  chainLink: ChainlinkPriceFeed;
};

export const factories = {
  ubiquiStick: TheUbiquityStick__factory.connect,
  ubiquiStickSale: TheUbiquityStickSale__factory.connect,
  simpleBond: SimpleBond__factory.connect,
  chainLink: ChainlinkPriceFeed__factory.connect,
};
