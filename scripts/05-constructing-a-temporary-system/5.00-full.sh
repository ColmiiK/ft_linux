#!/bin/bash

# This script will execute the whole chapter in one go, without any tests.

me=$(basename $0)

for script in *; do
  step=${script::4}
  case "$step" in
  "5.00" | "5.35" | "5.36") ;;
  *)
    echo "Executing $script..."
    # bash $script
    ;;
  esac
done

echo "All done!"
