#!/bin/bash

LOGFILE="/var/log/portscanner/portscanner.log"

# help menu
usage()
{
   # Display Help
   echo "Script to fetch open ports in local system."
   echo
   echo "Syntax: $0 [i|e]"
   echo "options:"
   echo "-i     Report interval."
   echo "-e     Exclude ports from report."
   echo
   exit 1
}

# Core function, takes interval and whitelist as arguments
openports()
{
  INTERVAL="$1"
  WHITELIST="$2"
  HOST=$(`which hostname`)
  NETSTAT_OUT=$(netstat -tuln4 | grep 'LISTEN' | awk '{print $4}' | grep 0.0.0.0 | cut -d':' -f2 | sort -un)
  mapfile -t portlist < <(echo "${NETSTAT_OUT}")
  OPENPORTS=$(echo "[${portlist[@]}]" | tr " " ",")

  if [ -z "$WHITELIST" ]
  then
    echo "No whitelist specified"
  else
    IFS=',' read -ra WHITEPORTS <<< "$WHITELIST"
    #echo "${WHITEPORTS[@]}"
    for port in ${WHITEPORTS[@]}
    do
      OPENPORTS=("${OPENPORTS[@]/$port,}")  
    done
  fi
  
  while true; do
    echo "$HOST": "$OPENPORTS" >>"$LOGFILE" 2>&1
    sleep "$INTERVAL";
  done
}

# Get the options
while getopts ":i:e:h" option; do
   case $option in
      h) # Display usage menu
         usage;;
      i) # Enter report interval
	 INTERVAL=$OPTARG
	 iflag=1;;
      e) # Enter ports to exclude in the report
	 WHITELIST=$OPTARG
	 eflag=1;;
      \?) # Invalid option
         echo "Error: Invalid option"
	 usage;;
   esac
done

if [ -z "$iflag" ] ; then
     INTERVAL=3
     echo "No interval specified. Default to $INTERVAL"
fi
if [ -z "$eflag" ] ; then
     WHITELIST=""
     echo "No ports to be whitelisted from the report"
fi

openports $INTERVAL $WHITELIST
