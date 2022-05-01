#!/usr/bin/env bash

echo
echo "installing nft..."
echo
cd contracts/ubiquistick && yarn
echo
echo "...complete!"
echo

echo
echo "building nft..."
echo
yarn build
echo
echo "...complete!"
echo

echo
echo "installing dollar..."
echo
cd ../dollar && yarn
echo
echo "...complete!"
echo

echo
echo "building dollar..."
echo
yarn build
echo
echo "...complete!"
echo

echo
echo "starting ui..."
echo
yarn next start
echo
echo "...complete!"
echo
