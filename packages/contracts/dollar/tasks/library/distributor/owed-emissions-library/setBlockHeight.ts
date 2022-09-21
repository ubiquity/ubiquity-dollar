import { Network } from "hardhat/types";
import { getAlchemyRpc } from "../../../hardhat.config";

export async function setBlockHeight(network: Network, blockHeight: number) {
  console.log(`Setting block height to ${blockHeight}...`);
  const response = await network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: getAlchemyRpc("mainnet"),
          blockNumber: blockHeight,
        },
      },
    ],
  });
  console.log(`...done!`);
  return response;
}
