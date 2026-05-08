#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/repo-valid.sh '.'; then
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`

secs=$1

if [ -z $secs ]; then
    secs=4
fi
# echo $PWD >> $PWD/peer.log
# echo "" >> $PWD/file.log

TIMEOUT_SECONDS=$((10 * 60))
START_TIME=$SECONDS

# LOGFILE="$LOCAL""_PUSH.log"
# touch ./$LOGFILE
LOGFILE="$LOCAL""_PUSH.log"
push_logn=`ls | grep PUSH | awk -F'PUSH' '{print $2}' | grep -iEo "[0-9]*" | awk '/[0-9]+/ { if ($0 > max) max = $0 } END { print max }'`

if [[ -z $push_logn ]]; then 
    touch ./$LOGFILE
else
    nfl=$((push_logn+1))
    LOGFILE="$LOCAL""_PUSH$nfl.log"
    touch ./$LOGFILE
fi 
echo "(tree) Log file created, interval=$secs s." > $LOGFILE

while true;do

    ELAPSED_TIME=$((SECONDS - START_TIME))
    if (( ELAPSED_TIME >= TIMEOUT_SECONDS )); then
        echo "Timeout reached after $TIMEOUT_SECONDS seconds. Exiting loop."
        break 
    fi

    for remote in `git remote`; do
        
        for group_refs in `git show-ref | grep refs/heads/groupConv | awk '{print $1}'`; do
            # commit_id=`git show -s $group_refs --no-show-signature --format='%H'`
            tree_id=`git show -s $group_refs --no-show-signature --format='%T'` 
            group_name=`git cat-file -p $tree_id:group_name`
            group_tree_id=`git cat-file -p $tree_id | grep tree | awk -F" " '{print $3}'`
            # echo `git cat-file -p $tree_id`
            
            # s1="Push tree id ($tree_id) group_name: $group_name to $remote"
            s1="from:$LOCAL, to: $remote, tree_id:$tree_id, group_name: $group_name"
            res=`$SCRIPTDIR/push-group-single.sh $group_name $remote`
            d=$(date "+%Y-%m-%d %T")
            uxt=$(echo $(date +%s.%N) '* 1000' | bc)
            s2="$d $uxt, $s1"
            echo -e "Pushing ($group_tree_id) to $remote.... Will append $s2 in $PWD/$LOGFILE\n"
            # echo $s1 >> $PWD/file.log
            # echo $d >> $PWD/file.log
            echo $s2 >> $PWD/$LOGFILE
            echo $res | sed 's/\r/\n/g' \
                      | grep -E 'done\.|To |remote:' \
                       >> $PWD/$LOGFILE
            echo -e "\n-----------------------------------------\n" >> $PWD/$LOGFILE
        done
        sleep .4
    done
    echo
    sleep $secs
done

echo "Push script stopped!"