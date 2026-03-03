#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${1:-$(pwd)/.github/scripts/build-storage-check-matrix.sh}"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

cd "$TMP_DIR"
git init -q

git config user.name "ci"
git config user.email "ci@example.com"

mkdir -p packages/contracts/src/dollar/core
mkdir -p packages/contracts/src/dollar/libraries

cat > packages/contracts/src/dollar/core/ExistingCore.sol <<'EOF'
contract ExistingCore { uint256 public a; }
EOF
cat > packages/contracts/src/dollar/libraries/LibExisting.sol <<'EOF'
library LibExisting { struct Layout { uint256 a; } }
EOF

git add .
git commit -qm "base"
BASE_SHA="$(git rev-parse HEAD)"

# Modify existing files + add new files
printf '\nuint256 public b;\n' >> packages/contracts/src/dollar/core/ExistingCore.sol
printf '\nuint256 b;\n' >> packages/contracts/src/dollar/libraries/LibExisting.sol
cat > packages/contracts/src/dollar/core/NewCore.sol <<'EOF'
contract NewCore { uint256 public z; }
EOF
cat > packages/contracts/src/dollar/libraries/LibNew.sol <<'EOF'
library LibNew { struct Layout { uint256 z; } }
EOF

git add .
git commit -qm "head"

# 1) No storage updates -> pass (empty matrix)
OUT_EMPTY="$(bash "$SCRIPT_PATH" "" "$BASE_SHA")"
[[ "$OUT_EMPTY" == "[]" ]]

# 2) Storage update, no collision -> existing contracts are included
OUT_EXISTING="$(bash "$SCRIPT_PATH" "packages/contracts/src/dollar/core/ExistingCore.sol" "$BASE_SHA")"
[[ "$OUT_EXISTING" == '["src/dollar/core/ExistingCore.sol:ExistingCore"]' ]]

# 3) Storage update, collision -> same inclusion behavior (collision is checked downstream)
OUT_COLLISION_PATH="$(bash "$SCRIPT_PATH" "packages/contracts/src/dollar/libraries/LibExisting.sol" "$BASE_SHA")"
[[ "$OUT_COLLISION_PATH" == '["src/dollar/libraries/LibExisting.sol:LibExisting"]' ]]

# 4) New contract/library added -> pass (skipped, empty matrix)
OUT_NEW_CORE="$(bash "$SCRIPT_PATH" "packages/contracts/src/dollar/core/NewCore.sol" "$BASE_SHA")"
[[ "$OUT_NEW_CORE" == "[]" ]]
OUT_NEW_LIB="$(bash "$SCRIPT_PATH" "packages/contracts/src/dollar/libraries/LibNew.sol" "$BASE_SHA")"
[[ "$OUT_NEW_LIB" == "[]" ]]

echo "All storage-matrix QA scenarios passed."
