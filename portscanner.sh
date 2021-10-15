#!/bin/bash

logfile="/var/log/portscanner/portscanner.log"
whitelist=()
interval=60

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
  #host=$(`which hostname`)

  echo "Report interval: "$interval"s"

  while true; do
    portlist=()
    openports=()
    netstat_out=$(netstat -tuln4 | grep 'LISTEN' | awk '{print $4}' | grep 0.0.0.0 | cut -d':' -f2 | sort -un)
    portlist+=($netstat_out)
    openports=("${portlist[@]}")

    # Check if there are open ports
    if [[ ! "${#openports[@]}" -eq 0 ]]; then
        # Check if whitelist is specified
        if [ ! -z "$whitelist" ]; then
	  IFS=',' read -ra whiteports <<< "$whitelist"
	  # Apply the whitelist
	  for port in "${whiteports[@]}"; do
            for target in "${!openports[@]}"; do
	      if [[ "${openports[target]}" = "$port" ]]; then
	         unset 'openports[target]'
	      fi
	    done
	  done
        fi
    else
      echo "No open ports"
    fi

    if [ "${#openports[@]}" -eq 0 ]; then
      openports+=(null)
      echo "["${openports[*]}"]"
    fi

    # Separate items with commas
    ports="${openports[*]}"
    ports=$(echo "$ports" | tr " " ",")
    data=("$ports")

    ##echo "$host": "[${openports[*]}]" >>"$logfile" 2>&1
    echo "["$data"]" >>"$logfile" 2>&1
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
