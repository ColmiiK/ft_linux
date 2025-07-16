#!/bin/bash

# This script will execute the whole chapter in one go, without any tests.

me=$(basename $0)

for script in *; do
  if [ $script == $me ]; then
    continue
  fi
  echo "Executing script $script..."
  bash $script
done

echo "All done!"
