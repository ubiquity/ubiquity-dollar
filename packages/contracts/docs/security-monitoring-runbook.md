# Security Monitoring Runbook (Issue #927)

This runbook describes the incident monitor for `LibUbiquityPool` and the automated protection workflow.

## What is monitored

- `IUbiquityPool.collateralUsdBalance()` at each monitor interval.
- Incident heuristic: a sudden drop in collateral USD value exceeding the configured threshold (default **30%**).

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
- `ADMIN_PRIVATE_KEY` (preferred; must have permissions to pause token and manage pool)
- `PRIVATE_KEY` (fallback if `ADMIN_PRIVATE_KEY` is unset; same required permissions)
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

Example cron every 5 minutes (with lock to prevent overlapping runs):

> **Note:** Replace `/path/to/ubiquity-dollar/` with your actual repository path.

```bash
*/5 * * * * flock -n /tmp/ubq-security-monitor.lock -c "cd /path/to/ubiquity-dollar/packages/contracts && npx tsx scripts/task/task.ts SecurityMonitor --network=mainnet" >> /var/log/ubq-security-monitor.log 2>&1
```

## Operational notes

- First run only stores baseline and does not trigger actions.
- If monitor connectivity fails, no on-chain action is sent.
- If notification transport fails, incident handling still executes; check monitor logs for transport errors.
- Keep admin key isolated (prefer dedicated guardian account with least required permissions).
