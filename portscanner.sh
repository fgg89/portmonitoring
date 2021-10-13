#!/bin/bash

logfile="/var/log/portscanner/portscanner.log"
whitelist=""
interval=3

# help menu
usage()
{
   # Display Help
   echo "Script to fetch open ports in local system."
   echo
   echo "Syntax: $0 [i|e|h]"
   echo "options:"
   echo "-i     Report interval in seconds. Default $interval seconds"
   echo "-e     Exclude list of comma-separated port numbers from report."
   echo "-h     Print this menu."
   echo
   exit 1
}

# Core function, takes interval and whitelist as arguments
openports()
{
  interval="$1"
  whitelist="$2"
  host=$(`which hostname`)

  echo "Report interval: "$interval"s"

  while true; do
    netstat_out=$(netstat -tuln4 | grep 'LISTEN' | awk '{print $4}' | grep 0.0.0.0 | cut -d':' -f2 | sort -un)
    mapfile -t portlist < <(echo "${netstat_out}")
    openports=$(echo "${portlist[*]}")

    if [ ${#openports[@]} -eq 0 ]; then
      openports="None"
    fi

    # If whitelist is specified then remove those ports from the openports array
    if [ ! -z "$whitelist" ]; then
      IFS=',' read -ra whiteports <<< "$whitelist"
      for port in "${whiteports[@]}"
      do
        openports=( "${openports[@]/$port}" )  
      done
    fi

    # Remove leading and trailing spaces and separate items with commas
    openports=$(echo "${openports[*]}" | awk '{$1=$1};1'| tr " " ",")

    echo "$host" "[$openports]" >>"$logfile" 2>&1
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
	 if [[ ! "$interval" =~ $re ]]; then
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

openports "$interval" "$whitelist"
