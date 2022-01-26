import { round, formatFixed } from "./lib/utils";
import SectionTitle from "./lib/SectionTitle";

export type BondData = {
  tokenName: string;
  claimed: number;
  rewards: number;
  claimable: number;
  depositAmount: number;
  endsAtBlock: number;
  endsAtDate: Date;
  rewardPrice: number;
};

const toTimeInWords = (time: number): string => {
  const days = Math.floor(time / (1000 * 60 * 60 * 24));
  const hours = Math.floor((time % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((time % (1000 * 60 * 60)) / (1000 * 60));
  return `${days}d ${hours}h ${minutes}m`;
};

const YourBonds = ({ isWhitelisted, bonds, onClaim }: { isWhitelisted: boolean; bonds: BondData[] | null; onClaim: () => void }) => {
  if (!bonds) return null;

  const accumulated = bonds.reduce((acc, bond) => acc + bond.claimable, 0);

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
          {bonds.length > 0 ? (
            <tbody>
              {bonds.map((bond, i) => (
                <tr key={i}>
                  <td className="py-2 px-2 whitespace-nowrap border-0 border-r border-solid border-white border-opacity-10">{bond.tokenName}</td>
                  <td className="py-2 px-2 w-full text-left border-0 border-r border-solid border-white border-opacity-10">
                    <div className="flex">
                      <div className="flex-grow">
                        {formatFixed(round(bond.claimable + bond.claimed))}
                        {" / "}
                        {formatFixed(round(bond.rewards))} uAR{" "}
                      </div>
                      <div className="text-white text-opacity-50 text-sm" title={`Ends at block: ${bond.endsAtBlock}`}>
                        {toTimeInWords(+bond.endsAtDate - +new Date())} left
                      </div>
                    </div>
                  </td>
                  <td className="py-2 px-2">{formatFixed(round(bond.claimable))} uAR</td>
                </tr>
              ))}
            </tbody>
          ) : (
            <tbody>
              <tr>
                <td colSpan={3} className="py-2 text-white text-opacity-50">
                  You've got no bonds yet
                </td>
              </tr>
            </tbody>
          )}
        </table>
      </div>
      <div className="text-lg mb-2">Accumulated claimable</div>
      <div className="text-3xl mb-6 text-accent drop-shadow-light">{formatFixed(round(accumulated))} uAR</div>
      <button className="btn-primary" disabled={!isWhitelisted || bonds.length === 0 || accumulated === 0} onClick={onClaim}>
        Claim all
      </button>
    </div>
  );
};

export default YourBonds;
