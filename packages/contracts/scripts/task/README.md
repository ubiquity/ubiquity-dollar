# Dollar task scripts

## BlocksInWeek

BlocksInWeek task provides a close approximate of number of blocks mined in one week.

Usage:

Ethereum mainnet:

```
npx tsx scripts/task/task.ts BlocksInWeek --network=mainnet
```

Sepolia:

Ethereum mainnet:

```
npx tsx scripts/task/task.ts BlocksInWeek --network=sepolia
```

Prerequisite: set ETHERSCAN_API_KEY in .env

## SecurityMonitor

Monitors `LibUbiquityPool` liquidity and automatically executes protective actions when a suspicious withdrawal is detected (default threshold: 30%).

Protective actions:

1. Pause `UbiquityDollarToken`
2. Disable each enabled collateral path (`toggleCollateral`)
3. Pause mint/redeem/borrow per collateral (`toggleMintRedeemBorrow`)
4. Send alert to configured webhook and/or Telegram

Usage:

```bash
cd packages/contracts
npx tsx scripts/task/task.ts SecurityMonitor --network=mainnet
```

Dry run (no on-chain transactions):

```bash
npx tsx scripts/task/task.ts SecurityMonitor --network=mainnet --dryrun
```

Config via environment variables (in `packages/contracts/.env`):

- `UBQ_DIAMOND_ADDRESS` (required)
- `UBQ_DOLLAR_TOKEN_ADDRESS` (required)
- `SECURITY_MONITOR_THRESHOLD_BPS` (optional, default `3000`)
- `SECURITY_MONITOR_STATE_FILE` (optional)
- `SECURITY_MONITOR_WEBHOOK_URL` (optional)
- `SECURITY_MONITOR_TELEGRAM_BOT_TOKEN` (optional)
- `SECURITY_MONITOR_TELEGRAM_CHAT_ID` (optional)
- `SECURITY_MONITOR_TELEGRAM_THREAD_ID` (optional, topic-ready)