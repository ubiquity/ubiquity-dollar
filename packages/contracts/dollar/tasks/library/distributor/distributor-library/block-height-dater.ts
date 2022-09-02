import EthDater from "ethereum-block-by-date";
import { ethers } from "ethers";
const provider = new ethers.providers.CloudflareProvider();

export default async function blockHeightDater(range: string[]) {
  const dater = new EthDater(
    provider // Ethers provider, required.
  );

  // Getting block by period duration. For example: every first block of month's midnights between vesting start and vesting end
  let blocks = dater.getEvery(
    "months", // Period, required. Valid value: years, quarters, months, weeks, days, hours, minutes
    range[0], // Start date, required. Any valid moment.js value: string, milliseconds, Date() object, moment() object.
    range[range.length - 1], // End date, required. Any valid moment.js value: string, milliseconds, Date() object, moment() object.
    1, // Duration, optional, integer. By default 1.
    true, // Block after, optional. Search for the nearest block before or after the given date. By default true.
    false // Refresh boundaries, optional. Recheck the latest block before request. By default false.
  ) as EthDaterExampleResult[];

  return blocks;
}

export interface EthDaterExampleResult {
  date: string;
  block: number;
  timestamp: number;
}

// export type EthDaterExampleResults = [
//   {
//     date: "2022-05-01T00:00:00Z";
//     block: 14688630;
//     timestamp: 1651363205;
//   },
//   {
//     date: "2022-06-01T00:00:00Z";
//     block: 14881677;
//     timestamp: 1654041601;
//   },
//   {
//     date: "2022-07-01T00:00:00Z";
//     block: 14890291; // this is the current block because its in the future when this was run on 2 june 2022
//     timestamp: 1654163340;
//   },
//   {
//     date: "2022-08-01T00:00:00Z";
//     block: 14890291; // this is the current block because its in the future when this was run on 2 june 2022
//     timestamp: 1654163340;
//   },
//   {
//     date: "2022-09-01T00:00:00Z";
//     block: 14890291; // ...
//     timestamp: 1654163340;
//   }
// ];
