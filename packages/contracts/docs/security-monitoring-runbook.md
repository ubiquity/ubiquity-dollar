# Security Monitoring Runbook (Issue #927)

This runbook describes the incident monitor for `LibUbiquityPool` and the automated protection workflow.

## What is monitored

- `IUbiquityPool.collateralUsdBalance()` at each monitor interval.
- Incident heuristic: a sudden drop of collateral USD value above the configured threshold (default **30%**).

## What happens on incident

When `dropBps >= SECURITY_MONITOR_THRESHOLD_BPS`:

1. Pause `UbiquityDollarToken` (`pause()`)
2. For each collateral in `allCollaterals()`:
   - disable collateral if currently enabled (`toggleCollateral(index)`)
   - pause mint/redeem/borrow path if currently unpaused (`toggleMintRedeemBorrow(index, 0|1|2)`)
3. Emit notifications to configured webhook and/or Telegram topic.

## Configuration

Set these in `packages/contracts/.env`:

- `RPC_URL`
- `ADMIN_PRIVATE_KEY` (must have permissions to pause token and manage pool)
- `UBQ_DIAMOND_ADDRESS`
- `UBQ_DOLLAR_TOKEN_ADDRESS`
- `SECURITY_MONITOR_THRESHOLD_BPS` (default `3000`)
- `SECURITY_MONITOR_STATE_FILE` (default `./monitoring/security-monitor-state.json`)
- Optional notifications:
  - `SECURITY_MONITOR_WEBHOOK_URL`
  - `SECURITY_MONITOR_TELEGRAM_BOT_TOKEN`
  - `SECURITY_MONITOR_TELEGRAM_CHAT_ID`
  - `SECURITY_MONITOR_TELEGRAM_THREAD_ID`

## Execution

Initialize baseline (first run):

```bash
cd packages/contracts
npx tsx scripts/task/task.ts SecurityMonitor --network=mainnet
```

Run in dry mode (simulate only):

```bash
npx tsx scripts/task/task.ts SecurityMonitor --network=mainnet --dryrun
```

## Suggested automation

Example cron every 5 minutes:

```bash
*/5 * * * * cd /path/to/ubiquity-dollar/packages/contracts && npx tsx scripts/task/task.ts SecurityMonitor --network=mainnet >> /var/log/ubq-security-monitor.log 2>&1
```

## Operational notes

- First run only stores baseline and does not trigger actions.
- If monitor connectivity fails, no on-chain action is sent.
- If notification transport fails, incident handling still executes; check monitor logs for transport errors.
- Keep admin key isolated (prefer dedicated guardian account with least required permissions).
