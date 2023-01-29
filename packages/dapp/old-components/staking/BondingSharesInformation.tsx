import { BigNumber, ethers } from "ethers";
import { formatEther } from "old-components/lib/format";
import DepositShare from "./DepositShare";
import Icon from "../ui/Icon";
import { Model, Actions } from "./BondingSharesExplorer";
import { BondingShareRow } from "./BondingShareRow";

export const BondingSharesInformation = ({ shares, totalShares, onWithdrawLp, onClaimUbq, onStake, processing, walletLpBalance }: Model & Actions) => {
  const totalUserShares = shares.reduce((sum, val) => {
    return sum.add(val.stakingTokenBalance);
  }, BigNumber.from(0));

  const totalLpBalance = shares.reduce((sum, val) => {
    return sum.add(val.stake.lpAmount);
  }, BigNumber.from(0));

  const totalPendingUgov = shares.reduce((sum, val) => sum.add(val.rewards), BigNumber.from(0));

  const poolPercentage = formatEther(totalUserShares.mul(ethers.utils.parseEther("100")).div(totalShares));

  const filteredShares = shares.filter(({ stake: { lpAmount }, rewards: ugov }) => lpAmount.gt(0) || ugov.gt(0));

  return (
    <div>
      <DepositShare onStake={onStake} disabled={processing.length > 0} maxLp={walletLpBalance} />
      <table id="Staking">
        <thead>
          <tr>
            <th>Action</th>
            <th>Rewards</th>
            <th>Unlock Time</th>
            <th>Est. Deposit</th>
          </tr>
        </thead>
        {filteredShares.length > 0 ? (
          <tbody>
            {filteredShares.map((share) => (
              <BondingShareRow
                key={share.id.toString()}
                {...share}
                disabled={processing.includes(share.id)}
                onWithdrawLp={onWithdrawLp}
                onClaimUbq={onClaimUbq}
              />
            ))}
          </tbody>
        ) : (
          <tbody>
            <tr>
              <td colSpan={5}>Nothing staked yet</td>
            </tr>
          </tbody>
        )}
      </table>

      <table>
        <tbody>
          <tr>
            <td>
              <span>Pending</span>
            </td>
            <td>
              <Icon icon="ubq" />
            </td>
            <td>
              <span>{formatEther(totalPendingUgov)} </span>
            </td>
          </tr>
          <tr>
            <td>
              <span>Staked LP</span>
            </td>
            <td>
              <Icon icon="liquidity" />
            </td>
            <td>{formatEther(totalLpBalance)}</td>
          </tr>
          <tr>
            <td>Ownership</td>
            <td>%</td>
            <td>{poolPercentage}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};
