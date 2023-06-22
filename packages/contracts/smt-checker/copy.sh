#!/bin/bash

sudo cp libz3.so libz3.so.4.11
sudo mv libz3.so.4.11 x86_64-linux-gnu && echo "Successfully copied Z3 to the system"
