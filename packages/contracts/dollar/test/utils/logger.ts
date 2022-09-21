import { BigNumber, ethers } from "ethers";

export default function logETH(bigN: BigNumber, desc?: string): void {
  console.log(`-- ${desc ? `${desc}:` : ""}${ethers.utils.formatEther(bigN)}`);
}
