import { Button } from "@/ui";
import * as widget from "../ui/widget";
import { BondData } from "./lib/hooks/useSimpleBond";
import { format, formatFixed, round } from "./lib/utils";

const toTimeInWords = (time: number): string => {
  const days = Math.floor(time / (1000 * 60 * 60 * 24));
  const hours = Math.floor((time % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((time % (1000 * 60 * 60)) / (1000 * 60));
  return `${days}d ${hours}h ${minutes}m`;
};

const YourBonds = ({
  enabled,
  bonds,
  onClaim,
  uarUsdPrice,
}: {
  enabled: boolean;
  bonds: BondData[] | null;
  onClaim: () => void;
  uarUsdPrice: number | null;
}) => {
  if (!bonds || bonds.length === 0) return null;

  const accumulated = bonds.reduce((acc, bond) => acc + bond.claimable, 0);
  const accumulatedInUsd = uarUsdPrice ? accumulated * uarUsdPrice : null;

  return (
    <widget.Container>
      <widget.Title text="Your Bonds" />
      <widget.SubTitle text="Claim the accumulated flow" />

      <div>
        <table>
          <thead>
            <tr>
              <th>Bond</th>
              <th>Progress</th>
              <th>Claimable</th>
            </tr>
          </thead>
          {bonds.length > 0 ? (
            <tbody>
              {bonds.map((bond, i) => (
                <tr key={i}>
                  <td>{bond.tokenName}</td>
                  <td>
                    <div>
                      <div>
                        {formatFixed(round(bond.claimable + bond.claimed))}
                        {" / "}
                        {formatFixed(round(bond.rewards))} uCR{" "}
                      </div>
                      <div title={`Ends at block: ${bond.endsAtBlock}`}>{toTimeInWords(+bond.endsAtDate - +new Date())} left</div>
                    </div>
                  </td>
                  <td>{formatFixed(round(bond.claimable))} uCR</td>
                </tr>
              ))}
            </tbody>
          ) : (
            <tbody>
              <tr>
                <td colSpan={3}>You've got no bonds yet</td>
              </tr>
            </tbody>
          )}
        </table>
      </div>
      <div>Accumulated claimable</div>
      <div>
        {format(round(accumulated))} uCR {accumulatedInUsd !== null ? <span>(${format(round(accumulatedInUsd))})</span> : null}
      </div>
      <div>
        <Button disabled={!enabled || bonds.length === 0 || accumulated === 0} onClick={onClaim}>
          Claim all
        </Button>
      </div>
    </widget.Container>
  );
};

export default YourBonds;
