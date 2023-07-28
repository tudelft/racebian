#!/bin/bash

echo "$@"
deploy=$(echo "$@" | awk -F= '{a[$1]=$2} END {print(a["--deploy"])}')
echo $deploy
