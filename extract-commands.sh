#!/bin/bash

# Extracts the name of the package
curl -s $1 | pup 'h1 text{}' | tr '\n' ' ' | awk '{print $NF}'
# Extracts all of the commands found in the page
curl -s $1 | pup 'kbd.command text{}' | python3 -c 'import sys, html; print(html.unescape(sys.stdin.read()), end="")'

# Macro for setting the tarball name and specific steps
#Vuv$dma/tarballnwlpji€kb'aV/chrokdko€kb€kb/specijp:w
