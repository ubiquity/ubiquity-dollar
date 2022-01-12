import { useEffect, useState } from "react";
import { round, formatFixed } from "./lib/utils";
import SectionTitle from "./lib/SectionTitle";

type Bond = {
  tokenName: string;
  total: number;
  dripped: number;
  claimed: number;
};

const REFRESH_BONDS_INTERVAL = 1000;

const BONDING_TIME = 1000 * 60 * 60 * 24 * 5;

const yourBondsMock: Bond[] = [
  {
    tokenName: "DAI-ETH",
    total: 2540,
    dripped: 1600,
    claimed: 1100,
  },
  {
    tokenName: "USDC-ETH",
    total: 3000,
    dripped: 1000,
    claimed: 0,
  },
  {
    tokenName: "uAR-ETH",
    total: 12000,
    dripped: 9000,
    claimed: 4000,
  },
];

let lastAdvanced = new Date();
const mockAdvance = (bonds: Bond[]): Bond[] => {
  const currentTime = new Date();
  const advanceSpan = +currentTime - +lastAdvanced;
  const result = bonds.map((bond) => {
    const drippedOverSpan = (advanceSpan / BONDING_TIME) * bond.total;
    const dripped = bond.dripped + drippedOverSpan;
    return {
      ...bond,
      dripped: dripped < bond.total ? dripped : bond.total,
    };
  });
  lastAdvanced = currentTime;
  return result;
};

const toTimeInWords = (time: number): string => {
  const days = Math.floor(time / (1000 * 60 * 60 * 24));
  const hours = Math.floor((time % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((time % (1000 * 60 * 60)) / (1000 * 60));
  return `${days}d ${hours}h ${minutes}m`;
};

const YourBonds = ({ isWhitelisted }: { isWhitelisted: boolean }) => {
  const [bonds, setBonds] = useState<Bond[]>(yourBondsMock);
  useEffect(() => {
    const interval = setTimeout(() => {
      setBonds(mockAdvance(bonds));
    }, REFRESH_BONDS_INTERVAL);
    return () => clearTimeout(interval);
  }, [bonds]);

  const accumulated = bonds.reduce((acc, bond) => acc + bond.dripped - bond.claimed, 0);

  return (
    <div className="party-container">
      <SectionTitle title="Your Bonds" subtitle="Claim the accumulated flow" />
      <div className="mb-6 inline-block border border-solid border-white border-opacity-10 rounded">
        <table className="table border-collapse m-0">
          <thead className="border-0 border-b border-solid border-white border-opacity-10">
            <tr>
              <th>Bond</th>
              <th className="text-left">Progress</th>
              <th>Claimable</th>
            </tr>
          </thead>
          <tbody>
            {bonds.map((bond) => (
              <tr key={bond.tokenName}>
                <td className="py-2 px-2 whitespace-nowrap border-0 border-r border-solid border-white border-opacity-10">{bond.tokenName}</td>
                <td className="py-2 px-2 w-full text-left border-0 border-r border-solid border-white border-opacity-10">
                  <div className="flex">
                    <div className="flex-grow">
                      {formatFixed(round(bond.dripped))}
                      {" / "}
                      {formatFixed(round(bond.total))} uAR{" "}
                    </div>
                    <div className="text-white text-opacity-50 text-sm">{toTimeInWords((bond.dripped / bond.total) * BONDING_TIME)} left</div>
                  </div>
                </td>
                <td className="py-2 px-2">{formatFixed(round(bond.dripped - bond.claimed))} uAR</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="text-lg mb-2">Accumulated claimable</div>
      <div className="text-3xl mb-6 text-accent drop-shadow-light">{formatFixed(round(accumulated))} uAR</div>
      <button className="btn-primary" disabled={!isWhitelisted}>
        Claim all
      </button>
    </div>
  );
};

export default YourBonds;
