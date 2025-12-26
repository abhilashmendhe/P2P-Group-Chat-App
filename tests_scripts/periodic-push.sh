#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/repo-valid.sh '.'; then
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`

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

LOGFILE="$LOCAL""_PUSH.log"
push_logn=`ls | grep PUSH | awk -F'PUSH' '{print $2}' | grep -iEo "[0-9]*" | awk '/[0-9]+/ { if ($0 > max) max = $0 } END { print max }'`

if [[ -z $push_logn ]]; then 
    touch ./$LOGFILE
else
    nfl=$((push_logn+1))
    LOGFILE="$LOCAL""_PUSH$nfl.log"
    touch ./$LOGFILE
fi 

echo "Log file created for k=$k, and interval=$secs s." > $LOGFILE
# echo $LOGFILE

while true; do 
    
    ELAPSED_TIME=$((SECONDS - START_TIME))
    if (( ELAPSED_TIME >= TIMEOUT_SECONDS )); then
        echo "Timeout reached after $TIMEOUT_SECONDS seconds. Exiting loop."
        break 
    fi

    for((i=0; i<k; i++)); do 
        # echo $i
        remote=`git remote | shuf -n 1`
        # echo -e "Pushing to $remote\n"
        for group_refs in `git show-ref | grep refs/heads/groupConv | awk '{print $1}'`; do
            # commit_id=`git show -s $group_refs --no-show-signature --format='%H'`
            tree_id=`git show -s $group_refs --no-show-signature --format='%T'` 
            group_name=`git cat-file -p $tree_id:group_name`
            group_tree_id=`git cat-file -p $tree_id | grep tree | awk -F" " '{print $3}'`
            
            s1="from:$LOCAL, to: $remote, tree_id:$tree_id, group_name: $group_name"
            res=`$SCRIPTDIR/push-group-single.sh $group_name $remote`
            d=$(date "+%Y-%m-%d %T")
            uxt=$(echo $(date +%s.%N) '* 1000' | bc)
            s2="$d $uxt, $s1"
            echo -e "Pushing ($group_tree_id) to $remote.... Will append $s2 in $PWD/$LOGFILE\n"
            echo $s2 >> $PWD/$LOGFILE
            echo $res | sed 's/\r/\n/g' \
                        | grep -E 'done\.|To |remote:' \
                        >> $PWD/$LOGFILE
            echo -e "\n-----------------------------------------\n" >> $PWD/$LOGFILE
        done
        sleep .4
    done 
    sleep $secs
done
    

echo "Push script stopped!!!"
