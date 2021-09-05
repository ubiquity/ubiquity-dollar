/// <reference types="next" />
/// <reference types="next/types/global" />

import { ethers } from "ethers";

declare global {
  interface Window {
    ethereum?: ethers.providers.ExternalProvider;
  }
  declare type Maybe<T> = T | null;
}

export {};
