#!/bin/bash


HOST=$(`which hostname`)
NETSTAT_OUT=$(netstat -tuln4 | grep 'LISTEN' | awk '{print $4}' | grep 0.0.0.0 | cut -d':' -f2 | sort -un)
mapfile -t portlist < <(echo "${NETSTAT_OUT}")
OPENPORTS=$(echo "[${portlist[@]}]" | tr " " ",")

echo "$HOST": "$OPENPORTS"




