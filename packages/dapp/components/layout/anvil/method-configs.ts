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
    type: "utility",
  },
  {
    name: "Anvil Info",
    methodName: "anvil_nodeInfo",
    description: "Retrieves the configuration params for the currently running Anvil node.",
    params: [],
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
    methodName: "eth_sendUnsignedTransaction",
    description:
      "Returns the details of all transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.",
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
    type: "chain",
  },
  {
    name: "Txpool Status",
    methodName: "anvil_getTxpoolStatus",
    description:
      "Returns a summary of all the transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.",
    params: [],
    type: "chain",
  },
  {
    name: "Txpool Content",
    methodName: "anvil_getTxpoolContent",
    description:
      "Returns the details of all transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.",
    params: [],
    type: "chain",
  },
];

// /**
//  * Impersonate an account or contract address.
//  * This lets you send transactions from that account even if you
//  * don't have access to its private key.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/impersonateAccount.html
//  */
// const prank = async () => {
//   if (!prankArg) return console.log("prankArg is undefined");
//   await testClient.impersonateAccount({
//     address: prankArg,
//   });
//   setIsPranking(true);
// };

// /**
//  * Stop impersonating an account after having previously used
//  * [`impersonateAccount`](https://viem.sh/docs/actions/test/impersonateAccount.html).
//  *
//  * - Docs: https://viem.sh/docs/actions/test/stopImpersonatingAccount.html
//  */
// const stopPrank = async () => {
//   if (!prankArg) return console.log("prankArg is undefined");
//   await testClient.stopImpersonatingAccount({
//     address: prankArg,
//   });
//   setIsPranking(false);
// };

// /**
//  *
//  * Modifies the balance of an account.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setBalance.html
//  */
// const deal = async () => {
//   if (!dealArgs) return console.log("dealArgs is undefined");
//   await testClient.setBalance({
//     address: dealArgs[0],
//     value: dealArgs[1],
//   });
// };

// /**
//  * Jump forward in time by the given amount of time, in seconds.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/increaseTime.html
//  */
// const warpTime = async () => {
//   if (!warpTimeArg) return console.log("warpTimeArg is undefined");
//   await testClient.increaseTime({
//     seconds: warpTimeArg,
//   });
// };

// /**
//  * Mine a specified number of blocks.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/mine.html
//  */
// const rollBlocks = async () => {
//   if (!blockHeightArg) return console.log("blockHeightArg is undefined");
//   await testClient.mine({
//     blocks: blockHeightArg,
//   });
// };

// /**
//  * anvil_dumpState Returns a hex string representing the complete state
//  * of the chain. Can be re-imported into a fresh/restarted instance of Anvil
//  * to reattain the same state.
//  */
// const dumpState = async () => {
//   const tx = await testClient.request({
//     method: "anvil_dumpState",
//     params: [],
//   });
//   // needs written to file
//   console.log(tx);
// };

// /**
//  * anvil_loadState When given a hex string previously returned by anvil_dumpState,
//  * merges the contents into the current chain state.
//  * Will overwrite any colliding accounts/storage slots.
//  *
//  */

// const loadState = async () => {
//   await testClient.request({
//     method: "anvil_loadState",
//     params: [loadStateArg],
//   });
// };

// /**
//  * anvil_autoImpersonateAccount
//  * Accepts true to enable auto impersonation of accounts, and false to disable it.
//  * When enabled, any transaction's sender will be automatically impersonated.
//  */
// const autoImpersonateAccounts = async () => {
//   await testClient.request({
//     method: "anvil_autoImpersonateAccounts",
//     params: [],
//   });
// }

// /**
//  * anvil_nodeInfo Retrieves the configuration params for the currently running Anvil node.
//  */
// const getAnvilNodeInfo = async () => {
//   const tx = await testClient.request({
//     method: "anvil_getNodeInfo",
//     params: [],
//   });
//   console.log(tx);
// }

// /**
//  * anvil_enableTraces
//  * Turn on call traces for transactions that are returned to the user when they
//  * execute a transaction (instead of just txhash/receipt).
//  */
// const enableTraces = async () => {
//   await testClient.request({
//     method: "anvil_enableTraces",
//     params: [],
//   });
// }

// const getStorageAt = async () => {
//   if(!getStorageArgs) return console.log("getStorageArgs is undefined");

//   const tx = await testClient.request({
//     method: "anvil_getStorageAt",
//     params: [getStorageArgs[0], getStorageArgs[1], getStorageArgs[2]],
//   });
// };

// /**
//  * Writes to a slot of an account's storage.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setStorageAt.html
//  */
// const setStorageAt = async () => {
//   if (!setStorageArgs) return console.log("setStorageArgs is undefined");
//     await testClient.setStorageAt({
//       address: setStorageArgs[0],
//       index: setStorageArgs[1],
//       value: setStorageArgs[2],
//     });
//   };

// const [snapshot, setSnapshot] = React.useState<string>("");

// /**
//  * Snapshot the state of the blockchain at the current block.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/snapshot.html
//  */
// const getSnapshot = async () => {
//   const snap = await testClient.snapshot();
//   console.log(snap);
//   setSnapshot(snap);
//   // needs written to file
// };

// const [rpcUrl, setRpcUrl] = React.useState<string>("http://localhost:8545");

// /**
//   * Sets the backend RPC URL.
//   *
//   * - Docs: https://viem.sh/docs/actions/test/setRpcUrl.html
//   */
// const changeRpcUrl = async () => {
//   const change = await testClient.setRpcUrl({
//     url: "http://localhost:8545",
//   });
//   console.log(change);

// };

// const [nonce, setNonce] = React.useState<number>(0);

// /**
//  * Modifies (overrides) the nonce of an account.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setNonce.html
//  */
// const setAccountNonce = async () => {
//   const tx = await testClient.setNonce({
//     address: "0x1234...90123", //TODO
//     nonce: nonce,
//   });
//   console.log(tx);
// };

// /**
//  * Sets the next block's timestamp.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setNextBlockTimestamp.html
//  */
// const setNextBlockTimestamp = async () => {
//   const tx = await testClient.setNextBlockTimestamp({
//     timestamp: 1, //TODO
//   });
//   console.log(tx);
// };

// /**
//  * Sets the next block's base fee per gas.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setNextBlockBaseFeePerGas.html
//  */
// const setNextBlockBaseFeePerGas = async () => {
//   const tx = await testClient.setNextBlockBaseFeePerGas({
//     baseFeePerGas: 1, //TODO
//   });
//   console.log(tx);
// };

// /**
//  * Change the minimum gas price accepted by the network (in wei).
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setMinGasPrice.html
//  *
//  * Note: `setMinGasPrice` can only be used on clients that do not have EIP-1559 enabled.
//  */
// const setMinGasPrice = async () => {
//   const tx = await testClient.setMinGasPrice({
//     minGasPrice: 1, //TODO
//   });
//   console.log(tx);
// };

// /**
//  * Enable or disable logging on the test node network.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setLoggingEnabled.html
//  */
// const setLoggingEnabled = async () => {
//   const tx = await testClient.setLoggingEnabled(true);
//   console.log(tx);
// };

// /**
//  * Sets the automatic mining interval (in seconds) of blocks.
//  * Setting the interval to 0 will disable automatic mining.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setIntervalMining.html
//  */

// const setIntervalMining = async () => {
//   const tx = await testClient.setIntervalMining({
//     interval: 1, //TODO
//   });

//   console.log(tx);
// };

// /**
//  * Sets the coinbase address to be used in new blocks.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setCoinbase.html
//  */
// const setCoinbase = async () => {
//   const tx = await testClient.setCoinbase({
//     address: "0x1234...90123", //TODO
//   });
//   console.log(tx);
// };

// /**
//  * Modifies the bytecode stored at an account's address.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setCode.html
//  */
// const setCode = async () => {
//   const tx = await testClient.setCode({
//     address: "0x1234...90123", //TODO
//     bytecode: "0x1234...90123", //TODO
//   });

//  /**
//   * Similar to [`increaseTime`](https://viem.sh/docs/actions/test/increaseTime.html),
//   * but sets a block timestamp `interval`. The timestamp of future blocks will
//   * be computed as `lastBlock_timestamp` + `interval`.
//   *
//   * - Docs: https://viem.sh/docs/actions/test/setBlockTimestampInterval.html
//   */
// const setBlockTimestampInterval = async () => {
//   const tx = await testClient.setBlockTimestampInterval({
//     interval: 1, //TODO
//   });
//     console.log(tx);
//   };

//  /**
//   * Removes [`setBlockTimestampInterval`](https://viem.sh/docs/actions/test/setBlockTimestampInterval.html)
//   * if it exists.
//   *
//   * - Docs: https://viem.sh/docs/actions/test/removeBlockTimestampInterval.html
//   */
// const removeBlockTimestampInterval = async () => {
//   const tx = await testClient.removeBlockTimestampInterval();
//   console.log(tx);
// };

//  /**
//   * Sets the block's gas limit.
//   *
//   * - Docs: https://viem.sh/docs/actions/test/setBlockGasLimit.html
//   */
// const setBlockGasLimit = async () => {
//   const tx = await testClient.setBlockGasLimit({
//     gasLimit: 1, //TODO
//   });

//   console.log(tx);
// };

// /**
//  * Enables or disables the automatic mining of new blocks
//  * with each new transaction submitted to the network.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/setAutomine.html
//  */
// const setAutomine = async () => {
//   const tx = await testClient.setAutomine(true);
//   console.log(tx);
// };

// /**
//  * Returns the details of all transactions currently pending for
//  * inclusion in the next block(s), as well as the ones that are being
//  * scheduled for future execution only.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/getTxpoolContent.html
//  */
// const sendUnsignedTransaction = async () => {
//   const tx = await testClient.sendUnsignedTransaction({
//     from: "0x1234...90123", //TODO
//     to: "0x1234...90123", //TODO
//     value: 1, //TODO
//   });
//   console.log(tx);
// };

// /**
//  * Revert the state of the blockchain at the current block.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/revert.html
//  */
// const revertTransaction = async () => {
//   const tx = await testClient.revert({
//     id: '0x', //TODO
//   });
//   console.log(tx);
// };

// /**
//  * Resets fork back to its original state.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/reset.html
//  */
// const resetFromBlockNumber = async () => {
//   const tx = await testClient.reset({
//     blockNumber: 1n, //TODO
//   })
//   console.log(tx);
// };

// /**
//  * * Returns a summary of all the transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/inspectTxpool.html
//  */
// const inspectTxpool = async () => {
//   const tx = await testClient.inspectTxpool();
//   console.log(tx);
// };

// /**
//  * * Returns a summary of all the transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/getTxpoolStatus.html
//  */
// const getTxpoolStatus = async () => {
//   const tx = await testClient.getTxpoolStatus();
//   console.log(tx);
// };

// /**
//  * * Returns the details of all transactions currently pending for inclusion in the next block(s), as well as the ones that are being scheduled for future execution only.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/getTxpoolContent.html
//  */
// const getTxpoolContent = async () => {
//   const tx = await testClient.getTxpoolContent();
//   console.log(tx);
// };

// /**
//  * Returns the automatic mining status of the node.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/getAutomine.html
//  */
// const getAutomine = async () => {
//   const tx = await testClient.getAutomine();
//   console.log(tx);
// };

// /**
//  * * Removes a transaction from the mempool.
//  *
//  * - Docs: https://viem.sh/docs/actions/test/dropTransaction.html
//  */
// const dropTransaction = async () => {
//   const tx = await testClient.dropTransaction({
//     hash: '0x', //TODO
//   });
//   console.log(tx);
// };
