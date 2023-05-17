#!/bin/bash

set -e # exit on error

# generates lcov.info
forge coverage --report lcov

# Foundry uses relative paths but Hardhat uses absolute paths.
# Convert absolute paths to relative paths for consistency.
sed -i -e 's/\/.*solidity.//g' lcov.info

# Merge lcov files
lcov \
    --rc lcov_branch_coverage=1 \
    --add-tracefile lcov.info \
    --output-file merged-lcov.info

# Filter out node_modules, test, and mock files
lcov \
    --rc lcov_branch_coverage=1 \
    --remove merged-lcov.info \
    --output-file filtered-lcov.info \
    "*node_modules*" "*test*" "*mock*" "*scriptscripting*"


# Generate summary
lcov \
    --rc lcov_branch_coverage=1 \
    --list filtered-lcov.info

# Open more granular breakdown in browser
if [ "$CI" != "true" ]
then
    genhtml \
        --rc genhtml_branch_coverage=1 \
        --output-directory coverage \
        filtered-lcov.info
    open coverage/index.html
fi