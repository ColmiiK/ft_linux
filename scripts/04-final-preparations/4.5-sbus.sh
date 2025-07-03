#!/bin/bash

echo "MAKEFLAGS=-j 2" >>/etc/environment
echo 'Relog and run "echo $MAKEFLAGS" for confirmation'
