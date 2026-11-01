# Dollar security monitoring

This worker monitors the pool diamond's raw ERC20 collateral balances and requests
an emergency shutdown when **more than 30% of any collateral** disappears within
a rolling block window. It sends incident and shutdown-status messages to
the configured Telegram chat/topic. Nothing is deployed or registered merely by
checking out this code.

## On-chain prerequisite

Upgrade the diamond's `UbiquityPoolFacet` implementation, replacing its existing
selectors and **adding `pausePool()`** through the normal reviewed diamond-cut
process. No storage migration is required. Existing deployments do not expose
this new selector until upgraded.

`pausePool()` requires `PAUSER_ROLE` in the diamond's access control. It disables
**all** registered collateral, including collateral added since the worker
started. Calling it again never enables collateral. Disabling collateral blocks
minting, redemption, redemption collection, and AMO borrowing. It does not pause
other, unrelated protocol contracts.

Grant a dedicated, gas-funded monitor signer only `keccak256("PAUSER_ROLE")` via
`AccessControlFacet.grantRole`. Do **not** grant `DEFAULT_ADMIN_ROLE`. The worker
calls `UbiquityDollarToken.pause()` separately using that same role/manager, so
one failed transaction does not prevent the other shutdown attempt. Note that the
existing token role also permits token unpausing; protect the signer accordingly.

## Worker configuration

Use the repository's supported Node version (20.10+) and installed contracts
workspace dependencies (`ethers` is already declared). Inject these environment
variables using your service/secret manager; do not put credentials in Git:

| Variable                     | Value                                                                                               |
| ---------------------------- | --------------------------------------------------------------------------------------------------- |
| `MONITOR_RPC_URL`            | Trusted Ethereum RPC with historical `eth_call` support for the entire lookback window              |
| `MONITOR_POOL_ADDRESS`       | Pool **diamond** address, not the facet implementation                                              |
| `MONITOR_DOLLAR_ADDRESS`     | Dollar token **proxy** address, not its implementation                                              |
| `MONITOR_PRIVATE_KEY`        | Dedicated funded pauser signer, supplied as a runtime secret                                        |
| `MONITOR_TELEGRAM_BOT_TOKEN` | Runtime secret for a Telegram bot allowed to post in UbiquityDAO                                    |
| `MONITOR_TELEGRAM_CHAT_ID`   | Numeric chat ID of the UbiquityDAO group (`t.me/UbiquityDAO` is not a chat ID)                      |
| `MONITOR_TELEGRAM_TOPIC_ID`  | Optional numeric forum topic ID; create a `Dollar monitoring` topic as a group admin                |
| `MONITOR_STATE_FILE`         | Absolute path to a persistent, writable incident-state file outside the checkout; parent must exist |
| `MONITOR_CHAIN_ID`           | Expected chain ID; default `1`                                                                      |
| `MONITOR_LOOKBACK_BLOCKS`    | Positive block window; default `300` (roughly one hour on Ethereum)                                 |
| `MONITOR_CONFIRMATIONS`      | Positive confirmation depth for observations and receipts; default `2`                              |
| `MONITOR_POLL_MS`            | Positive polling interval in milliseconds; default `15000`                                          |

Resolve and independently verify proxy/diamond addresses from the reviewed
mainnet deployment broadcast (`Deploy001_Diamond_Dollar_Governance.s.sol/1/run-latest.json`)
and current chain state. No addresses or secrets are hard-coded. Startup verifies
the chain, token/pool relationship, signer role, and new selector with `eth_call`.

Run one supervised worker per target, with automatic restart, persistent storage,
and independent process/RPC/balance health alerts:

```sh
yarn workspace @ubiquity/contracts monitor:security
# One poll, suitable for a supervised external scheduler:
yarn workspace @ubiquity/contracts monitor:security --once
# Dependency-free runtime tests (also included in test:unit):
node --test packages/contracts/scripts/monitoring/liquidity-monitor-test.mjs
# Focused on-chain regression tests from packages/contracts:
forge test --match-contract UbiquityPoolFacetTest --match-test testPausePool
```

Before production, exercise a >30% drop on a local deployment/fork, check both
transactions and Telegram delivery, test retries with an unfunded signer and a
Telegram outage, and verify the service restarts with the same state file. Bot
creation, group/topic permissions, role grants, diamond upgrades and service
provisioning are operator actions; this repository does not perform them.

## Detection and recovery semantics

- Compare native token balances at `head - confirmations` with balances
  `lookback` blocks earlier, not with the immediately preceding poll. Each asset
  is checked independently, so deposits of another asset cannot mask its loss.
  The collateral list comes from the historical block; newly added assets gain
  coverage once they have a full lookback window. Cumulative withdrawals within
  that window are covered, including after a worker restart. Exactly 30%, a zero
  baseline, and balance increases do not trigger shutdown.
- Detection uses raw ERC20 `balanceOf(diamond)` amounts, including reserved
  collateral, with no oracle/decimal conversion. The pool's free-USD getter can
  revert if theft leaves less collateral than pending redemptions; it is not
  used. The per-asset threshold is conservative relative to aggregate liquidity.
  Legitimate redemption collection and AMO borrowing can trigger it; deposits of
  the same asset can mask withdrawals. This is a circuit breaker, not proof of an
  exploit. Slower drains outside the window and outages before detection are
  limitations. RPC/token read failures never masquerade as zero liquidity.
- An incident is durably latched before responding. Notification failures do not
  stop either on-chain action. Confirmed actions are recorded; unconfirmed
  actions and failed alerts retry on later polls, even if liquidity recovers.
  Telegram requests time out after 10 seconds and transaction receipt waits
  after 60 seconds. The initial alert starts without delaying pool shutdown;
  status changes are notified without repeating unchanged alerts every poll.
- The two shutdown transactions are **not atomic**. Monitor unconfirmed-status
  alerts immediately. Never treat a submission as confirmation. A transaction
  may mine after a timeout; pool shutdown is idempotent and the token's pause
  state is checked before retrying. Keep enough ETH for emergency gas spikes.
- Successful shutdown remains latched and there is **no automatic unpause**.
  After investigation, stop the worker, recover the token/collateral explicitly
  with the authorized governance accounts, archive the state file, and restart
  with a new state file once the observation window is safe to monitor again.
  Do not delete state just to silence an unresolved incident. State is bound to
  the chain, addresses, window and confirmation depth; invalid/mismatched state
  stops startup for manual review. Never share a state file between workers.
- A degraded-RPC alert is attempted on polling errors. Startup failures and
  repeated persistence/notification errors also need independent supervisor
  alerting: Telegram cannot report its own outage. Logs deliberately suppress
  raw HTTP/provider errors because they may contain credentials.
