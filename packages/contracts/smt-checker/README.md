# SMT-Checker support for our smart contract testing

## Steps

## Download and Install Z3

g++, python3
sudo apt-get install g++
### sudo apt-get install z3
### sudo apt-get install libz3-dev

sudo wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-4.11.0.tar.gz
          sudo tar -zxvf z3-4.11.0.tar.gz
          cd z3-z3-4.11.0
          python3 scripts/mk_make.py
          cd build
          echo $PWDs
          sudo make -j$(nproc)
          sudo make install
          sudo cp libz3.so libz3.so.4.11
          sudo mv libz3.so.4.11 x86_64-linux-gnu

          You've successfully installed Z3 for the Solidity Compiler to detect it

## Make sure your system has Z3 installed >= "version"

