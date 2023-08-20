import React from "react";
import Button from "../ui/button";
import { createTestClient, http } from "viem";
import { foundry } from "viem/chains";

export default function AnvilRpcs() {
  const [isHidden, setIsHidden] = React.useState<boolean>(true);
  const [prankArg, setPrankArg] = React.useState<`0x${string}`>();
  const [warpTimeArg, setWarpTimeArg] = React.useState<number>(0);
  const [blockHeightArg, setBlockHeightArg] = React.useState<number>(0);
  const [loadStateArg, setLoadStateArg] = React.useState<string>("");
  const [dealArgs, setDealArgs] = React.useState<[`0x${string}`, bigint]>(["0x", 0n]);
  const [setStorageArgs, setSetStorageArgs] = React.useState<[`0x${string}`, `0x${string}`, `0x${string}`]>(["0x", 0n, 0n]);
  const [pranking, setIsPranking] = React.useState<boolean>(false);

  const testClient = createTestClient({
    chain: foundry,
    mode: "anvil",
    transport: http(),
  });

  const prank = async () => {
    if (!prankArg) return console.log("prankArg is undefined");
    await testClient.impersonateAccount({
      address: prankArg,
    });
    setIsPranking(true);
  };

  const stopPrank = async () => {
    if (!prankArg) return console.log("prankArg is undefined");
    await testClient.stopImpersonatingAccount({
      address: prankArg,
    });
    setIsPranking(false);
  };

  const deal = async () => {
    if (!dealArgs) return console.log("dealArgs is undefined");
    await testClient.setBalance({
      address: dealArgs[0],
      value: dealArgs[1],
    });
  };

  const setStorageAt = async () => {
    if (!setStorageArgs) return console.log("setStorageArgs is undefined");
    await testClient.setStorageAt({
      address: setStorageArgs[0],
      index: setStorageArgs[1],
      value: setStorageArgs[2],
    });
  };

  const warpTime = async () => {
    if (!warpTimeArg) return console.log("warpTimeArg is undefined");
    await testClient.increaseTime({
      seconds: warpTimeArg,
    });
  };

  const rollBlocks = async () => {
    if (!blockHeightArg) return console.log("blockHeightArg is undefined");
    await testClient.mine({
      blocks: blockHeightArg,
    });
  };

  const dumpState = async () => {
    const tx = await testClient.request({
      method: "anvil_dumpState",
      params: [],
    });
    // needs written to file
    console.log(tx);
  };

  const loadState = async () => {
    await testClient.request({
      method: "anvil_loadState",
      params: [loadStateArg],
    });
  };

  const prankArgToState = async (e: React.ChangeEvent<HTMLInputElement>) => {
    setPrankArg(e.target.value);
  };

  const dealArgsToState = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const args = e.target.value.split(",");
    args[0] as `0x${string}`;
    args[1] as `${bigint}`;
    setDealArgs(args);
  };

  const setStorageArgsToState = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const args = e.target.value.split(",");
    args[0] as `0x${string}`;
    args[1] as `0x${string}`;
    args[2] as `0x${string}`;
    setSetStorageArgs(args);
  };

  const warpTimeArgToState = async (e: React.ChangeEvent<HTMLInputElement>) => {
    setWarpTimeArg(Number(e.target.value));
  };

  const blockHeightArgToState = async (e: React.ChangeEvent<HTMLInputElement>) => {
    setBlockHeightArg(Number(e.target.value));
  };

  const loadStateArgToState = async (e: React.ChangeEvent<HTMLInputElement>) => {
    setLoadStateArg(e.target.value);
  };

  return (
    <div className="rpc-method-container">
      <div>
        <Button onClick={() => setIsHidden(!isHidden)}>Custom RPC Methods</Button>
        <div className="grid-container" style={{ display: isHidden ? "none" : "block" }}>
          {!pranking ? (
            <div>
              <Button className="grid-container-Button" onClick={() => prank()}>
                Prank
              </Button>
              <input type="text" name="prank" onChange={(e) => prankArgToState(e)} placeholder="0x1234...90123 (address to impersonate)" />
            </div>
          ) : (
            <div>
              <Button className="grid-container-Button" onClick={() => stopPrank()}>
                Stop Prank
              </Button>
            </div>
          )}

          <div>
            <Button className="grid-container-Button" onClick={() => deal()}>
              Deal
            </Button>
            <input type="text" name="deal" onChange={(e) => dealArgsToState(e)} placeholder="0x1234...90123,10 (address and value)" />
          </div>

          <div>
            <Button className="grid-container-Button" onClick={() => setStorageAt()}>
              setStorageAt
            </Button>
            <input type="text" name="setStorageAt" onChange={(e) => setStorageArgsToState(e)} placeholder="0x1234....7890,2,12 (address, index, value)" />
          </div>

          <div>
            <Button className="grid-container-Button" onClick={() => warpTime()}>
              warpTime
            </Button>
            <input type="text" name="warpTime" onChange={(e) => warpTimeArgToState(e)} placeholder="15 (seconds)" />
          </div>

          <div>
            <Button className="grid-container-Button" onClick={() => rollBlocks()}>
              rollBlocks
            </Button>
            <input type="text" name="rollBlocks" onChange={(e) => blockHeightArgToState(e)} placeholder="15 (blocks)" />
          </div>

          <div>
            <Button className="grid-container-Button" onClick={() => loadState()}>
              loadState
            </Button>
            <input type="text" name="loadState" onChange={(e) => loadStateArgToState(e)} placeholder="0x1f8b080......." />
          </div>
          <div>
            <Button className="grid-container-Button" onClick={() => dumpState()}>
              dumpState
            </Button>
            <input type="text" name="dumpState" onChange={(e) => loadStateArgToState(e)} placeholder="dump it." />
          </div>
        </div>
      </div>
    </div>
  );
}
