import { ethers } from "ethers";
import useWeb3 from "../lib/hooks/use-web-3";

const { provider, walletAddress, signer } = useWeb3();

const LUSD = new ethers.Contract(
  "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0",
  [
    "function decimals() view returns (uint8)",
    "function name() view returns (string)",
    "function version() view returns (string)",
    "function nonces(address owner) view returns (string)",
    `function permit(
      address owner,
      address spender,
      uint256 value,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
    )`,
  ],
  signer
);

const cowZap = (sellToken: string) => {
  const Token = new ethers.Contract(
    sellToken,
    [
      "function decimals() view returns (uint8)",
      "function name() view returns (string)",
      "function version() view returns (string)",
      "function nonces(address owner) view returns (string)",
      `function permit(
      address owner,
      address spender,
      uint256 value,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
    )`,
    ],
    signer
  );
};
