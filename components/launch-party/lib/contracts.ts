import { ChainlinkPriceFeed, ChainlinkPriceFeed__factory } from "../../../abi/types";
import { ERC20 } from "../../../contracts/artifacts/types";
import {
  TheUbiquityStickSale__factory,
  SimpleBond__factory,
  SimpleBond,
  TheUbiquityStickSale,
  TheUbiquityStick,
  TheUbiquityStick__factory,
} from "../../../the-ubiquity-stick/types";

type Addresses = {
  ubiquiStick: string;
  ubiquiStickSale: string;
  simpleBond: string;
  chainLinkEthUsd: string;
};

export const addresses: { [key: string]: Addresses } = {
  "1": {
    ubiquiStick: "0xaab265cceb890c0e6e09aa6f5ee63b33de649374",
    ubiquiStickSale: "0x035e4568f2738917512e4222a8837ad22d21bb1d",
    simpleBond: "0x0000000000000000000000000000000000000000",
    chainLinkEthUsd: "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419",
  },
  "31337": {
    ubiquiStick: "0xEd1F68A18003dC4d1d22c4c47fdCBd860F02aCC2",
    ubiquiStickSale: "0xE3e000631087A0dC36F4b1A1c82b3371067f1b24",
    simpleBond: "0x9CAA4E6472457A2Ed8295A270abE76FD3dBd3e6D",
    chainLinkEthUsd: "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419",
  },
};

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
