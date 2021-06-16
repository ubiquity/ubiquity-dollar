#!/bin/bash

git add .
git commit -am "build"
# git push --set-upstream origin feature/build-vercel
cd ~/Downloads
rm -rf ./uad-ui-launch-testenv/
git clone https://github.com/pavlovcik/uad-ui-launch.git uad-ui-launch-testenv/
cd ./uad-ui-launch-testenv/
hooks/next-build.sh
