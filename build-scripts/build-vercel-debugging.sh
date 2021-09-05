#!/bin/bash

git add .
git commit -am "build"
# git push --set-upstream origin feature/build-vercel
git push
cd ~/Downloads
rm -rf ./uad-ui-launch-testenv/
git clone https://github.com/pavlovcik/uad-ui-launch.git uad-ui-launch-testenv/
cd ./uad-ui-launch-testenv/
build-scripts/build-vercel.sh
