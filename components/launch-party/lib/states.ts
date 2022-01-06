import { atom, selector } from "recoil";

export type PoolData = {
  liquidity1: number;
  liquidity2: number;
  poolTokenBalance: number;
  apy: number;
};

export type PoolsData = { [key: string]: PoolData };

export type PoolsDataState = null | PoolsData;

export const poolsDataState = atom<PoolsDataState>({ key: "poolsDataState", default: null });

export type Bond = {
  tokenName: string;
  total: number;
  dripped: number;
  claimed: number;
};

export type BondsState = null | Bond[];

export const bondsState = atom<BondsState>({ key: "bondsState", default: null });

export type OwnedSticks = {
  standard: number;
  gold: number;
};

export type OwnedSticksState = null | OwnedSticks;

export const ownedSticksState = atom<OwnedSticksState>({ key: "ownedStickState", default: null });

export const sticksCountState = selector({
  key: "sticksCountState",
  get: ({ get }) => {
    const owned = get(ownedSticksState);
    return owned ? owned.standard + owned.gold : 0;
  },
});

export type SticksAllowance = {
  count: number;
  price: number;
};

export type SticksAllowanceState = null | SticksAllowance;

export const sticksAllowanceState = atom<SticksAllowanceState>({ key: "sticksAllowanceState", default: null });

export const isWhitelistedState = selector({
  key: "isWhitelistedState",
  get: ({ get }) => {
    const allowance = get(sticksAllowanceState);
    const sticksCount = get(sticksCountState);
    return allowance && sticksCount ? allowance.count > 0 || sticksCount > 0 : null;
  },
});
