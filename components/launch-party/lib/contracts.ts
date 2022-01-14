import { TheUbiquityStickSale__factory, SimpleBond__factory, SimpleBond, TheUbiquityStickSale, TheUbiquityStick, TheUbiquityStick__factory } from "./types";

type Addresses = {
  ubiquiStick: string;
  ubiquiStickSale: string;
  simpleBond: string;
};

export const addresses: { [key: string]: Addresses } = {
  "1": {
    ubiquiStick: "0xaab265cceb890c0e6e09aa6f5ee63b33de649374",
    ubiquiStickSale: "0x035e4568f2738917512e4222a8837ad22d21bb1d",
    simpleBond: "0x0000000000000000000000000000000000000000",
  },
  "31337": {
    ubiquiStick: "0x45379687D28B5CaDf738067Da1058eA9801d9897",
    ubiquiStickSale: "0x23EEe0f3fD17b25C16C712e90c77A6d165a54d2f",
    simpleBond: "0xf351c71e7199aD6669B1C6f5f507FabdE4054f04",
  },
};

export type Contracts = {
  ubiquiStick: TheUbiquityStick;
  ubiquiStickSale: TheUbiquityStickSale;
  simpleBond: SimpleBond;
};

export const factories = {
  ubiquiStick: TheUbiquityStick__factory.connect,
  ubiquiStickSale: TheUbiquityStickSale__factory.connect,
  simpleBond: SimpleBond__factory.connect,
};
