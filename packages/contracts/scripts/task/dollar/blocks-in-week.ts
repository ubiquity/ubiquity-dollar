import { OptionDefinition } from "command-line-args";

import { Networks, TaskFuncParam } from "../../shared";
import { EtherscanProvider } from "ethers";

export const optionDefinitions: OptionDefinition[] = [
  { name: "task", defaultOption: true },
  { name: "network", alias: "n", type: String },
];

const funcBlocksInAWeek = async (params: TaskFuncParam) => {
  const { args, env } = params;
  const { network } = args;

  const chainId = Networks[network] ?? undefined;
  if (!chainId) {
    throw new Error(`Unsupported network: ${network} Please configure it out first`);
  }

  const provider = new EtherscanProvider(chainId, env.etherscanApiKey);

  console.log(`Calculating number of blocks in the last week...`);
  const secondsInAWeek = 604800; // 24 * 7 * 60 * 60 seconds is one week
  const currentBlockNumber = await provider.getBlockNumber();
  const currentBlockTimestamp = (await provider.getBlock(currentBlockNumber))?.timestamp;
  const blockTimestampTwoBlocksAgo = (await provider.getBlock(currentBlockNumber - 2))?.timestamp;

  if (currentBlockTimestamp && blockTimestampTwoBlocksAgo) {
    const avgBlockTime = (currentBlockTimestamp - blockTimestampTwoBlocksAgo) / 2;
    console.log(`Recent average block time: ${avgBlockTime} seconds`);

    const oneWeekAgo = currentBlockTimestamp - secondsInAWeek;
    const estimatedBlocksInAWeek = secondsInAWeek / avgBlockTime;
    console.log(`Estimated blocks in a week best case ${estimatedBlocksInAWeek}`);

    let estimatedBlockNumber = currentBlockNumber - estimatedBlocksInAWeek;
    let estimatedBlockTimestamp = (await provider.getBlock(estimatedBlockNumber))?.timestamp;

    if (estimatedBlockTimestamp) {
      let deltaBlockTime = oneWeekAgo - estimatedBlockTimestamp;
      estimatedBlockNumber += Math.trunc(deltaBlockTime / avgBlockTime);
      estimatedBlockTimestamp = (await provider.getBlock(estimatedBlockNumber))?.timestamp || estimatedBlockTimestamp;
      deltaBlockTime -= estimatedBlockTimestamp - oneWeekAgo;

      console.log(`Produced ${estimatedBlocksInAWeek - deltaBlockTime / avgBlockTime} blocks, ${deltaBlockTime / avgBlockTime} worst than the best case`);
    }
  }

  return "succeeded";
};
export default funcBlocksInAWeek;
