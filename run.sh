#!/bin/bash
# Build and launch Dachsy Pet Widget
cd "$(dirname "$0")"
swift build 2>&1 && open .build/debug/PetWidget
