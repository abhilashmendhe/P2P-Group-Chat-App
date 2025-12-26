#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"


arch=$1

if [[ -z $arch ]]; then 
    echo "Please pass first arg as 'mesh' or 'tree'"
    exit 1
fi

if [[ $arch != "tree"  && $arch != "mesh" ]]; then 
    echo "First arg should be 'tree' or 'mesh'"
    exit 1
fi

mode=$2

if [[ -z $mode ]]; then 
    echo "Please pass second arg as 'pull' or 'pull-push'"
    exit 1
fi

if [[ $mode != "pull"  && $mode != "pull-push" ]]; then 
    echo "Second arg should be 'pull' or 'pull-push'"
    exit 1
fi

apath=""

if [[ $arch == "mesh" ]]; then
    apath=$SCRIPTDIR/../mesh-arch-testing
else 
    apath=$SCRIPTDIR/../tree-arch-testing
fi

if [[ $mode == "pull" ]]; then 
    apath="$apath/pull2"
else 
    apath="$apath/pull-push2"
fi 

# clean1="`sed 's/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/\n&\n/g'`"

for ks in `ls $apath`;do 

    for peer in `ls $apath/$ks`;  do 
        if [[ $peer == "stats.log" ]]; then 
            continue
        fi 
        pull_log=$apath/$ks/$peer/"$peer"_PULL.log
        # cat $pull_log
        sed 's/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/\n&\n/g' $pull_log > $apath/$ks/$peer/clean_pull1.log
        sed 's/Remotes ->/\n\n&/g' $apath/$ks/$peer/clean_pull1.log > $apath/$ks/$peer/clean_pull2.log
        sed -E 's/remote: (Counting|Compressing) objects: [0-9]+% \([0-9]+\/[0-9]+\)//g; s/\n+/ /g' $apath/$ks/$peer/clean_pull2.log > $apath/$ks/$peer/clean_pull3.log
        sed -E $'s/\x1b\\[K//g' $apath/$ks/$peer/clean_pull3.log > $apath/$ks/$peer/clean_pull4.log
        sed 's/Remotes -> NO OUTPUT NO CHANGE//g' $apath/$ks/$peer/clean_pull4.log > $apath/$ks/$peer/clean_pull5.log
        sed -E 's/^, done. /\n&\n/g' $apath/$ks/$peer/clean_pull5.log > $apath/$ks/$peer/clean_pull6.log
        sed -E 's/^, done. //g' $apath/$ks/$peer/clean_pull6.log > $apath/$ks/$peer/clean_pull7.log
        sed -E 's/^ +//; s/ +$//; /^\s*$/d;' $apath/$ks/$peer/clean_pull7.log > $apath/$ks/$peer/clean_pull8.log
        
        # break
        
    done 
    # break
done