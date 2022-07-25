import { ethers } from "ethers";
import { abi as tokenABI } from "../../../../artifacts/contracts/UbiquityGovernance.sol/UbiquityGovernance.json";
import { getKey } from "../../../../hardhat.config";
import blockHeightDater from "./block-height-dater";
import { verifyMinMaxBlockHeight } from "./verifyMinMaxBlockHeight";

interface Filter {
  address: string;
  fromBlock: number;
  toBlock: number;
}

export async function readContractTransactionHistory(address: string, queryDates: string[]) {
  const timestampsDated = await blockHeightDater(queryDates);
  const range = await verifyMinMaxBlockHeight(timestampsDated);

  let provider = new ethers.providers.EtherscanProvider(1, getKey("ETHERSCAN"));

  const filter = {
    address: address,
    fromBlock: range[0]?.block,
    toBlock: range[1]?.block,
  };

  return await getLogs(provider, filter);
}

async function getLogs(provider: ethers.providers.EtherscanProvider, filter: Filter): Promise<LogAndEvents[]> {
  // https://github.com/ethers-io/ethers.js/issues/487#issuecomment-481881691

  let tokenInterface = new ethers.utils.Interface(tokenABI);
  const logs = await provider.getLogs(filter);
  let logsAndEvents = logs.map((log) => {
    const events = tokenInterface.parseLog(log);
    return { log, events };
  });
  return logsAndEvents;
}

export interface LogAndEvents {
  log: ethers.providers.Log;
  events: ethers.utils.LogDescription;
}

/*
type ExampleLog = {
  blockNumber: 14693560;
  blockHash: "0xdfefdb6a69409d7c967957cfd1f127f28e5f6806bcec943e0e2f76035e76c9aa";
  transactionIndex: 157;
  removed: false;
  address: "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0";
  data: "0x0000000000000000000000000000000000000000000000ce218db29d696f2abf";
  topics: [
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
    "0x0000000000000000000000000b54b916e90b8f28ad21da40638e0724132c9c93",
    "0x000000000000000000000000f28211b8ee68914deed689e1079f882c421f0308"
  ];
  transactionHash: "0xa6075fa2ee0a786bf23a2371e1f057f9ca0af7e147b7904e265ec48ed76ab139";
  logIndex: 107;
}

type ExampleEvent = {
  "eventFragment": {
    "name": "Transfer",
    "anonymous": false,
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "indexed": true,
        "components": null,
        "arrayLength": null,
        "arrayChildren": null,
        "baseType": "address",
        "_isParamType": true
      },
      {
        "name": "to",
        "type": "address",
        "indexed": true,
        "components": null,
        "arrayLength": null,
        "arrayChildren": null,
        "baseType": "address",
        "_isParamType": true
      },
      {
        "name": "value",
        "type": "uint256",
        "indexed": false,
        "components": null,
        "arrayLength": null,
        "arrayChildren": null,
        "baseType": "uint256",
        "_isParamType": true
      }
    ],
    "type": "event",
    "_isFragment": true
  },
  "name": "Transfer",
  "signature": "Transfer(address,address,uint256)",
  "topic": "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
  "args": [
    "0x0B54B916E90b8f28ad21dA40638E0724132C9c93",
    "0xF28211B8ee68914dEeD689E1079F882C421F0308",
    {
      "type": "BigNumber",
      "hex": "0xce218db29d696f2abf"
    }
  ]
}
*/
