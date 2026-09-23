#!/bin/bash
set -e

SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
TARGET="arm64-apple-macosx13.0"

if [ "$1" == "test" ]; then
    echo "Building and running unit tests..."
    swiftc -sdk "$SDK_PATH" -target "$TARGET" \
        Sources/Cepaty/Core/*.swift \
        Sources/Cepaty/Utils/*.swift \
        Tests/CepatyTests/*.swift \
        -o run_tests
    ./run_tests
    rm -f run_tests
else
    echo "Building Cepaty executable..."
    swiftc -sdk "$SDK_PATH" -target "$TARGET" \
        Sources/Cepaty/CepatyApp.swift \
        Sources/Cepaty/Core/*.swift \
        Sources/Cepaty/ViewModels/*.swift \
        Sources/Cepaty/Views/*.swift \
        Sources/Cepaty/Utils/*.swift \
        -o Cepaty
    echo "Build complete: ./Cepaty"
fi
