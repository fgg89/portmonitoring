#!/bin/bash

logfile="/var/log/portscanner/portscanner.log"
whitelist=""

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
  interval="$1"
  whitelist="$2"
  host=$(`which hostname`)
  is_whitelist=false

  if [ ! -z "$whitelist" ]; then
    IFS=',' read -ra whiteports <<< "$whitelist"
    is_whitelist=true
  fi

  while true; do
    netstat_out=$(netstat -tuln4 | grep 'LISTEN' | awk '{print $4}' | grep 0.0.0.0 | cut -d':' -f2 | sort -un)
    mapfile -t portlist < <(echo "${netstat_out}")
    openports=$(echo "[${portlist[*]}]" | tr " " ",")

    if [ "$is_whitelist" = true ]; then
      for port in "${whiteports[@]}"
      do
        openports=("${openports[@]/$port,}")  
      done
    fi

    echo "$host": "$openports" >>"$logfile" 2>&1
    sleep "$interval";
  done
}

# Get the options
while getopts ":i:e:h" option; do
   case $option in
      h) # Display usage menu
         usage;;
      i) # Enter report interval
	 re='^[0-9]+$'
	 interval=$OPTARG
	 if [[ "$interval" =~ $re ]]; then
	   iflag=1
	 else
           echo "Interval not a number. Exiting"
	   exit 1
	 fi
	 ;;
      e) # Enter ports to exclude in the report
	 whitelist=$OPTARG;;
      \?) # Invalid option
         echo "Error: Invalid option"
	 usage;;
   esac
done

if [ -z "$iflag" ] ; then
     interval=3
     echo "No interval specified. Default to $interval"
fi

openports "$interval" "$whitelist"
