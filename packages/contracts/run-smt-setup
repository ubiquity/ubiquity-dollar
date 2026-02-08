#!/bin/bash

# Define paths
foundryTomlPath="foundry.toml"
backupFoundryTomlPath="foundry.toml.backup"
smtScriptPath="scripts/smt-checker/smt/smt.ts"

# Copy foundry.toml to backup file
cp -p "$foundryTomlPath" "$backupFoundryTomlPath"

# Run smt.ts script
npx tsx "$smtScriptPath"
