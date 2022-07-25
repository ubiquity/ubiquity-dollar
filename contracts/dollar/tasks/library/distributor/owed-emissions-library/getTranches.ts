import * as fs from "fs";


export async function getTranches() {
  const txListName = "../../distributor-transactions.json";
  const exists = fs.existsSync(txListName);
  if (exists) {
    return (await import(txListName)) as any[];
  } else {
    throw new Error("need to run another task first!");
  }
}
