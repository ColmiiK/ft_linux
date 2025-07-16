#!/bin/bash

# This script will execute from 6.07 Linux to 6.77 Eudev

me=$(basename $0)

for script in *; do
  step=${script::4}
  case "$step" in
  "6.02" | "6.03" | "6.05" | "6.06" | "6.79" | "6.80") ;;
  *)
    echo "Executing $script..."
    # bash $script
    ;;
  esac
done

echo "All done!"
