// https://viem.sh/docs/clients/test.html#test-client

export const methodConfigs = [
  {
    name: "Logging Enabled",
    methodName: "anvil_setLoggingEnabled",
    description: "Enable or disable logging on the test node network.",
    params: [{ name: "boolean", type: "boolean" }],
    type: "utility",
  },
  {
    name: "Load State",
    methodName: "anvil_loadState",
    description:
      "When given a hex string previously returned by anvil_dumpState, merges the contents into the current chain state. Will overwrite any colliding accounts/storage slots.",
    params: [{ name: "hexString", type: "string" }],
    type: "utility",
  },
  {
    name: "Dump State",
    methodName: "anvil_dumpState",
    description:
      "Returns a hex string representing the complete state of the chain. Can be re-imported into a fresh/restarted instance of Anvil to reattain the same state.",
    params: [],
    download: true,
    type: "utility",
  },
  {
    name: "Anvil Info",
    methodName: "anvil_nodeInfo",
    description: "Retrieves the configuration params for the currently running Anvil node.",
    params: [],
    download: true,
    type: "utility",
  },
  {
    name: "Enable Traces",
    methodName: "anvil_enableTraces",
    description: "Turn on call traces for transactions that are returned to the user when they execute a transaction (instead of just txhash/receipt).",
    params: [],
    type: "utility",
  },
  {
    name: "Snapshot",
    methodName: "anvil_snapshot",
    description: "Snapshot the state of the blockchain at the current block.",
    params: [],
    download: true,
    type: "utility",
  },
  {
    name: "Get Storage At",
    methodName: "eth_getStorageAt",
    description: "Returns the value of a storage slot at a given address.",
    params: [
      { name: "address", type: "string" },
      { name: "index", type: "string" },
      { name: "blockNumber", type: "string" },
    ],
    type: "utility",
  },

  {
    name: "Set Storage At",
    methodName: "anvil_setStorageAt",
    description: "Writes to a slot of an account's storage.",
    params: [
      { name: "address", type: "string" },
      { name: "index", type: "string" },
      { name: "value", type: "string" },
    ],
    type: "utility",
  },

  {
    name: "Set Anvil RPC",
    methodName: "anvil_setRpcUrl",
    description: "Sets the backend RPC URL.",
    params: [{ name: "url", type: "string" }],
    type: "chain",
  },
  {
    name: "Set Nonce",
    methodName: "anvil_setNonce",
    description: "Modifies (overrides) the nonce of an account.",
    params: [
      { name: "address", type: "string" },
      { name: "nonce", type: "number" },
    ],
    type: "user",
  },
  {
    name: "Increase Time",
    methodName: "anvil_increaseTime",
    description: "Jump forward in time by the given amount of time, in seconds.",
    params: [{ name: "seconds", type: "number" }],
    type: "chain",
  },
  {
    name: "Mine",
    methodName: "anvil_mine",
    description: "Mine a specified number of blocks.",
    params: [{ name: "blocks", type: "number" }],
    type: "chain",
  },
  {
    name: "Set Next block.timestamp",
    methodName: "anvil_setNextBlockTimestamp",
    description: "Sets the next block's timestamp.",
    params: [{ name: "timestamp", type: "number" }],
    type: "chain",
  },
  {
    name: "Set Next block.baseFeePerGas",
    methodName: "anvil_setNextBlockBaseFeePerGas",
    description: "Sets the next block's base fee per gas.",
    params: [{ name: "baseFeePerGas", type: "number" }],
    type: "chain",
  },
  {
    name: "Set Min Gas Price",
    methodName: "anvil_setMinGasPrice",
    description: "Change the minimum gas price accepted by the network (in wei).",
    params: [{ name: "minGasPrice", type: "number" }],
    type: "chain",
  },

  {
    name: "Mining Interval",
    methodName: "anvil_setIntervalMining",
    description: "Sets the automatic mining interval (in seconds) of blocks. Setting the interval to 0 will disable automatic mining.",
    params: [{ name: "interval", type: "number" }],
    type: "chain",
  },
  {
    name: "Set Coinbase",
    methodName: "anvil_setCoinbase",
    description: "Sets the coinbase address to be used in new blocks.",
    params: [{ name: "address", type: "string" }],
    type: "chain",
  },
  {
    name: "Set Code",
    methodName: "anvil_setCode",
    description: "Modifies the bytecode stored at an address.",
    params: [
      { name: "address", type: "string" },
      { name: "bytecode", type: "string" },
    ],
    type: "utility",
  },

  {
    name: "Block Gas Limit",
    methodName: "anvil_setBlockGasLimit",
    description: "Sets the block's gas limit.",
    params: [{ name: "gasLimit", type: "number" }],
    type: "chain",
  },
  {
    name: "Automine",
    methodName: "anvil_setAutomine",
    description: "Enables or disables the automatic mining of new blocks with each new transaction submitted to the network.",
    params: [{ name: "boolean", type: "boolean" }],
    type: "chain",
  },
  {
    name: "Unsigned Transaction",
    methodName: "sendUnsignedTransaction",
    description: "Sends an unsigned transaction.",
    params: [
      { name: "from", type: "string" },
      { name: "to", type: "string" },
      { name: "value", type: "number" },
    ],
    type: "user",
  },
  {
    name: "Revert",
    methodName: "anvil_revert",
    description: "Revert the state of the blockchain at the current block.",
    params: [{ name: "id", type: "bigint" }],
    type: "chain",
  },

  {
    name: "Get Automine",
    methodName: "anvil_getAutomine",
    description: "Returns the automatic mining status of the node.",
    params: [],
    type: "utility",
  },
  {
    name: "Drop Transaction",
    methodName: "anvil_dropTransaction",
    description: "Removes a transaction from the mempool.",
    params: [{ name: "hash", type: "string" }],
    type: "utlity",
  },
  {
    name: "Impersonate Account",
    methodName: "anvil_impersonateAccount",
    description:
      "Impersonate an account or contract address. This lets you send transactions from that account even if you don't have access to its private key.",
    params: [{ name: "address", type: "string" }],
    type: "user",
  },
  {
    name: "Stop Impersonating",
    methodName: "anvil_stopImpersonatingAccount",
    description: "Stop impersonating an account after having previously used anvil_impersonateAccount.",
    params: [{ name: "address", type: "string" }],
    type: "user",
  },
  {
    name: "Set Balance",
    methodName: "anvil_setBalance",
    description: "Modifies the balance of an account.",
    params: [
      { name: "address", type: "string" },
      { name: "value", type: "number" },
    ],
    type: "user",
  },
  {
    name: "Reset",
    methodName: "anvil_reset",
    description: "Resets fork back to its original state.",
    params: [],
    type: "chain",
  },
  {
    name: "Set Block Timestamp Interval",
    methodName: "anvil_setBlockTimestampInterval",
    description:
      "Similar to anvil_increaseTime, but sets a block timestamp interval. The timestamp of future blocks will be computed as lastBlock_timestamp + interval.",
    params: [{ name: "interval", type: "number" }],
    type: "chain",
  },
  {
    name: "Remove Block Timestamp Interval",
    methodName: "anvil_removeBlockTimestampInterval",
    description: "Removes anvil_setBlockTimestampInterval if it exists.",
    params: [],
    type: "chain",
  },
  {
    name: "Inspect Txpool",
    methodName: "anvil_inspectTxpool",
    description:
      "Returns a summary of all the transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.",
    params: [],
    download: true,
    type: "chain",
  },
  {
    name: "Txpool Status",
    methodName: "anvil_getTxpoolStatus",
    description:
      "Returns a summary of all the transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.",
    params: [],
    download: true,
    type: "chain",
  },
  {
    name: "Txpool Content",
    methodName: "anvil_getTxpoolContent",
    description:
      "Returns the details of all transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.",
    params: [],
    download: true,
    type: "chain",
  },
];
