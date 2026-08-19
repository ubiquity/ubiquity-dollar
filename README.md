# Storage Check CI Workflow Fix for New Contracts

## Summary of Changes
This fix resolves CI failures in `core-contracts-storage-check.yml` and `diamond-storage-check.yml` when newly created contracts or libraries are added.

### Root Cause
`tj-actions/changed-files@v42` by default filters on `*_any_changed` and outputs `*_all_changed_files`, which includes newly added files (`added_files`). When a new contract is added, `foundry-storage-check` attempts to download the storage layout artifact from the base branch / previous run. Since the contract is new and never existed before, no artifact is found, causing the job to fail with:
`No workflow run found with an artifact named...`

Newly added contracts have not undergone contract upgrades, so storage collision cannot occur. Only **modified** contracts require storage layout regression checks.

### Solution
1. Updated `steps.changed-contracts.outputs.contracts_any_changed == 'true'` to `steps.changed-contracts.outputs.contracts_any_modified == 'true'`.
2. Updated `CHANGED_CONTRACTS` from `contracts_all_changed_files` to `contracts_modified_files`.
3. Applied the identical fix to `diamond-storage-check.yml` using `libraries_any_modified` and `libraries_modified_files`.
4. Added safe quote handling and empty variable guards when generating `contracts.txt`.

---

## QA Test Scenarios

### Scenario 1: No storage updates
- **Action:** A PR modifies non-contract files (e.g., markdown, typescript configs).
- **Result:** `contracts_any_modified` is `false`, matrix outputs `[]`, storage check job is skipped, CI passes ✅.

### Scenario 2: Storage update without collision
- **Action:** Existing contract storage is appended safely with a new variable at the end of the storage layout.
- **Result:** `contracts_any_modified` is `true`, matrix triggers for modified contract, `foundry-storage-check` verifies layout compatibility, CI passes ✅.

### Scenario 3: Storage update with collision
- **Action:** Existing contract storage layout order/types are mutated or removed.
- **Result:** `contracts_any_modified` is `true`, `foundry-storage-check` detects collision/removal and fails with error, CI correctly fails ❌.

### Scenario 4: New contract / library added
- **Action:** A new `.sol` file is created under `packages/contracts/src/dollar/core/` or `packages/contracts/src/dollar/libraries/`.
- **Result:** `contracts_any_modified` is `false` (since file was added, not modified). Storage check job is skipped for new file, CI passes without artifact error ✅.
