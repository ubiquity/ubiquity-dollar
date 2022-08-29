import { EthDaterExampleResult } from "./block-height-dater";

export async function verifyMinMaxBlockHeight(timestampsDated: EthDaterExampleResult[]) {
  const vestingStart = timestampsDated.shift();
  const vestingEnd = timestampsDated.pop();

  if (!vestingStart || !vestingEnd) {
    throw new Error("vestingStart or vestingEnd is undefined");
  }
  return [vestingStart, vestingEnd] as EthDaterExampleResult[];
}
