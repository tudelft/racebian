#!/bin/bash

echo "$@"
test=$(echo "$@" | awk -F= '{a[$1]=$2} END {print(a["deploy"])}')
echo $test
