#!/bin/bash
file='unused-deps.txt'
echo "list all unused deps"

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPTS_DIR" || exit 1
cd "$(npm root)" || exit 1
cd .. || exit 1
PROJECT_ROOT=$(pwd) # guaranteed to be in this project's root
cd "$PROJECT_ROOT" || exit

npx depcheck >$file
n=1
while read -r line; do
    dep=$(echo "$line" | cut -c 3-)
    echo "uninstall : $dep"
    yarn remove "$dep" &
    n=$((n + 1))
done <$file
