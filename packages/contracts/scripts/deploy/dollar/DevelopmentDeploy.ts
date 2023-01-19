import { spawn } from "child_process";

(async () => {
  const command = spawn("cast", ["rpc", "anvil_impersonateAccount", "0x4486083589A063ddEF47EE2E4467B5236C508fDe", "-r", "http://localhost:8545"]);
  command.stdout.on("data", (output: any) => {
    console.log(output.toString());
  });
})();

(async () => {
  const command = spawn("cast", [
    "send",
    "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490",
    "0xa9059cbb000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb9226600000000000000000000000000000000000000000000021e19e0c9bab2400000",
    "--from",
    "0x4486083589A063ddEF47EE2E4467B5236C508fDe",
  ]);
  command.stdout.on("data", (output: any) => {
    console.log(output.toString());
  });
})();

(async () => {
  const command = spawn("cast", ["rpc", "anvil_stopImpersonatingAccount", "0x4486083589A063ddEF47EE2E4467B5236C508fDe", "-r", "http://localhost:8545"]);
  command.stdout.on("data", (output: any) => {
    console.log(output.toString());
  });
})();

(async () => {
  const command = spawn("forge", [
    "script",
    "scripts/deploy/dollar/solidityScripting/08_DevelopmentDeploy.s.sol:DevelopmentDeploy",
    "--fork-url http://localhost:8545",
    "--broadcast",
  ]);
  command.stdout.on("data", (output: any) => {
    console.log(output.toString());
  });
})();
