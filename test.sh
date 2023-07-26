#!/bin/bash

readarray -t arr2 < <(echo -e "Port 00:asdfadcd\nPort 03: heuakd" | grep "^Port " | sed "s/^Port \([0-9]\{2\}\).*$/\1/g" | sed -z "s/\n/ /g")

for port in ${arr2[@]}
do
    echo $port
    echo "asdf"
done

