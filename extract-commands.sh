#!/bin/bash

curl -s $1 | pup 'h1 text{}' | tr '\n' ' ' | awk '{print $NF}'
curl -s $1 | pup 'kbd.command text{}' | python3 -c 'import sys, html; print(html.unescape(sys.stdin.read()), end="")'


#Vuv$dma/tarballnwlpji€kb'aV/chrokdko€kb€kb/specijp:w
