import { Investor } from "./investor-types";

export function verifyDataShape(investor: Investor) {
  if (!investor.name) {
    console.warn("Investor should have a name");
  }
  if (typeof investor.name !== "string") {
    console.warn("Investor name should be a string");
  }

  if (!investor.address) {
    throw new Error("Investor must have an address");
  }
  if (typeof investor.address !== "string") {
    throw new Error("Investor address must be a string");
  }

  if (!investor.percent) {
    throw new Error("Investor must have a percentage");
  }
  if (typeof investor.percent !== "number") {
    throw new Error("Investor percentage must be a number");
  }
}
