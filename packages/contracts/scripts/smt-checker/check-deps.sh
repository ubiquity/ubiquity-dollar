#!/bin/bash

missing_dependencies=()

# Check if wget is installed
if ! command -v wget &>/dev/null; then
    missing_dependencies+=("wget")
fi

# Check if g++ is installed
if ! command -v g++ &>/dev/null; then
    missing_dependencies+=("g++")
fi

if [ ${#missing_dependencies[@]} -ne 0 ]; then
    echo "The following dependencies are missing: ${missing_dependencies[*]}"
    echo "Please install them to continue."
    echo "On Ubuntu/Debian, use the command:"
    echo "sudo apt-get install ${missing_dependencies[*]}"
    echo "On Arch Linux, use the command:"
    echo "sudo pacman -S ${missing_dependencies[*]}"
    echo "On macOS, you can install ${missing_dependencies[*]} by installing Xcode Command Line Tools:"
    echo "xcode-select --install"
    exit 1
fi

echo "All required programs are installed on your system."
