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
    # apath=$SCRIPTDIR/../mesh-arch-testing
    apath=$SCRIPTDIR/../single/mesh
else 
    # apath=$SCRIPTDIR/../tree-arch-testing
    apath=$SCRIPTDIR/../single/tree
fi

if [[ $mode == "pull" ]]; then 
    apath="$apath/pull"
else 
    apath="$apath/pull-push"
fi 

echo $apath
echo `ls $apath`
# exit 1
# clean1="`sed 's/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/\n&\n/g'`"

for ks in `ls $apath`;do 

    for peer in `ls $apath/$ks`;  do 
        if [[ $peer == "stats.log" ]]; then 
            continue
        fi 
        if [[ $arch == "mesh" ]]; then
            pull_log=$apath/$ks/$peer/"$peer"_PULL.log
            pull_path=$apath/$ks/$peer
        else
            if [[ $peer == *"ops"* || $peer == *"PUSH"* ]]; then
                continue
            fi
            pull_log=$apath/$ks/$peer
            pull_path=$apath/$ks
        fi
        echo $pull_log
        echo $pull_path
        # continue
        # cat $pull_log
        sed 's/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/\n&\n/g' $pull_log > $pull_path/clean_pull1.log
        sed 's/Remotes ->/\n\n&/g' $pull_path/clean_pull1.log > $pull_path/clean_pull2.log
        sed -E 's/remote: (Counting|Compressing) objects: [0-9]+% \([0-9]+\/[0-9]+\)//g; s/\n+/ /g' $pull_path/clean_pull2.log > $pull_path/clean_pull3.log
        sed -E $'s/\x1b\\[K//g' $pull_path/clean_pull3.log > $pull_path/clean_pull4.log
        sed 's/Remotes -> NO OUTPUT NO CHANGE//g' $pull_path/clean_pull4.log > $pull_path/clean_pull5.log
        sed -E 's/^, done. /\n&\n/g' $pull_path/clean_pull5.log > $pull_path/clean_pull6.log
        sed -E 's/^, done. //g' $pull_path/clean_pull6.log > $pull_path/clean_pull7.log
        sed -E 's/^ +//; s/ +$//; /^\s*$/d;' $pull_path/clean_pull7.log > $pull_path/clean_pull8.log
        
        # break
        
    done 
    # break
done