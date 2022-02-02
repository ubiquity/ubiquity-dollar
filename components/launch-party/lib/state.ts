import ethers from "ethers";
import { ERC20 } from "../../../contracts/artifacts/types";

export type OwnedSticks = {
  standard: number;
  gold: number;
};

export type SticksAllowance = {
  count: number;
  price: number;
};
