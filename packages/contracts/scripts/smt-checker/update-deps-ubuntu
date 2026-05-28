#!/bin/bash

# Install dependencies
sudo apt-get update && sudo apt-get install -y g++ && \
sudo apt-get install -y wget
sudo apt-get install -y z3 && \
sudo apt-get install -y libz3-dev && \

# Download and install Z3
sudo wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-4.11.0.tar.gz && \
sudo tar -zxvf z3-4.11.0.tar.gz && \
cd z3-z3-4.11.0 && \
sudo python3 scripts/mk_make.py && \
cd build && \
sudo make -j$(nproc) && \
sudo make install && \
sudo cp libz3.so libz3.so.4.11 && \
sudo mv libz3.so.4.11 /usr/lib/x86_64-linux-gnu && \
echo "Successfully copied Z3 to the system" && \

# Print success message
echo "Z3 installation completed successfully!"
