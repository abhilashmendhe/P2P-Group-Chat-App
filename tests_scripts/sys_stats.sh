#!/bin/bash

# TIMEOUT_SECONDS=$((10 * 60))
TIMEOUT_SECONDS=$((14 * 60))
START_TIME=$SECONDS

stat_file=$PWD/stats.log

while true; do 

    ELAPSED_TIME=$((SECONDS - START_TIME))
    if (( ELAPSED_TIME >= TIMEOUT_SECONDS )); then
        echo "Timeout reached after $TIMEOUT_SECONDS seconds. Exiting loop."
        break 
    fi

    d=$(date "+%Y-%m-%d %T")
    uxt=$(echo $(date +%s.%N) '* 1000' | bc)
    mem_usage=`free | sed -n '2p' | awk -F' ' '{print $3}'`
    cpu_usage=`mpstat -u | sed -n '4p'`
    user_cpu=`echo $cpu_usage | awk -F' ' '{print $4}'`
    sys_cpu=`echo $cpu_usage | awk -F' ' '{print $6}'`
    s2="$d $uxt,$user_cpu,$sys_cpu,$mem_usage"
    echo $s2 >> $stat_file
    sleep 2
done
