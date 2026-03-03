#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   build-storage-check-matrix.sh <changed-files> <base-sha>
#
# changed-files: whitespace/newline separated list of changed files from tj-actions/changed-files
# base-sha: commit sha used as baseline (e.g. github.event.pull_request.base.sha or github.event.before)

CHANGED_FILES="${1:-}"
BASE_SHA="${2:-}"

if [[ -z "${CHANGED_FILES//[[:space:]]/}" ]]; then
  echo "[]"
  exit 0
fi

MATRIX_ENTRIES=""

while IFS= read -r FILE; do
  [[ -z "$FILE" ]] && continue

  # Only process Solidity files inside packages/contracts
  [[ "$FILE" != packages/contracts/*.sol ]] && continue

  CONTRACT_NAME="$(basename "$FILE" .sol)"
  CONTRACT_PATH="${FILE#packages/contracts/}"
  ENTRY="${CONTRACT_PATH}:${CONTRACT_NAME}"

  # Newly-added contracts/libraries should be skipped from storage layout diff checks,
  # because no baseline artifact exists for them yet.
  if [[ -n "$BASE_SHA" ]] && git cat-file -e "${BASE_SHA}:${FILE}" 2>/dev/null; then
    MATRIX_ENTRIES+="${ENTRY}"$'\n'
  elif [[ -z "$BASE_SHA" ]]; then
    # Fallback for unusual contexts with no baseline sha.
    MATRIX_ENTRIES+="${ENTRY}"$'\n'
  else
    echo "Skipping new file without baseline on base sha: ${FILE}" >&2
  fi
done < <(printf '%s\n' "$CHANGED_FILES" | tr ' ' '\n')

printf '%s' "$MATRIX_ENTRIES" | jq -R -s -c 'split("\n")[:-1]'
