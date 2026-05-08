#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/repo-valid.sh '.'; then
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`
EMAIL="$LOCAL@unibas.ch"
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

k=$1
if [ -z $k ]; then 
    echo "Please specify number of remotes between 1-4"
    exit 1
fi

if [[ $k > 5 || $k < 1 ]];then 
    echo "Number of remotes must be between 1-4"
    exit 1
fi

secs=$2

if [ -z $secs ]; then
    secs=4
fi

TIMEOUT_SECONDS=$((10 * 60))
START_TIME=$SECONDS

LOGFILE="$LOCAL""_PULL.log"
pull_logn=`ls | grep PULL | awk -F'PULL' '{print $2}' | grep -iEo "[0-9]*" | awk '/[0-9]+/ { if ($0 > max) max = $0 } END { print max }'`

if [[ -z $pull_logn ]]; then 
    touch ./$LOGFILE
else
    nfl=$((pull_logn+1))
    LOGFILE="$LOCAL""_PULL$nfl.log"
    touch ./$LOGFILE
fi 
echo "Log file created for k=$k, and interval=$secs s." > $LOGFILE

while true; do

    ELAPSED_TIME=$((SECONDS - START_TIME))
    if (( ELAPSED_TIME >= TIMEOUT_SECONDS )); then
        echo "Timeout reached after $TIMEOUT_SECONDS seconds. Exiting loop."
        break 
    fi

    for((i=0; i<k; i++)); do 
        remote=`git remote | shuf -n 1`
        echo -e "Pulling from $remote\n"
        res=`$SCRIPTDIR/pull-group-single.sh $remote`
        s1="from:$remote, to: $LOCAL, tree_id:NA, group_name:NA"
	    d=$(date "+%Y-%m-%d %T")
        uxt=$(echo $(date +%s.%N) '* 1000' | bc)
        s2="$d $uxt, $s1"
        echo $s2 >> $PWD/$LOGFILE
        echo $res | sed 's/\r/\n/g' \
                        | grep -E 'done\.|To |remote:' \
                        >> ./$LOGFILE
        echo -e "\n-----------------------------------------\n" >> $PWD/$LOGFILE
        sleep .4
    done
    sleep $secs
    echo -e "\n##############################################\n" >> $PWD/$LOGFILE
    echo
done

echo "Pull script stopped!!!"
