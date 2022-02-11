export type OwnedSticks = {
  black: number;
  gold: number;
  invisible: number;
};

export type SticksAllowance = {
  count: number;
  price: number;
};

export type TokenData = {
  name: string;
  animation_url: string;
  image: string;
  type: "black" | "gold" | "invisible";
};

export type TokenMedia = {
  black?: TokenData;
  gold?: TokenData;
  invisible?: TokenData;
};
