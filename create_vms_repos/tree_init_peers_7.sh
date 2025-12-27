#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

repo_init_path="$SCRIPTDIR/../_1_repo_init/target/release/repo_init"
echo "$repo_init_path"

num_nodes=$1

if [[ -z $num_nodes ]]; then 
    echo "Please pass the first argument as a number"
    exit 1
fi

if [[ $num_nodes < 1 ]]; then 
    echo "Argument should be >= 1"
    exit 1
fi

# HEIGHT=$()

for (( i=1; i<=$num_nodes; i++)); do
    echo `$repo_init_path peer$i`
done

for ((i=1; i<=$num_nodes; i++)); do 
    lc=$((i*2))
    rc=$(((i*2) + 1))
    if [[ $lc -le $num_nodes ]]; then  
        # echo $PWD
        # echo "$i -> $lc"
        cd $PWD/peer$i
        echo `git remote add peer$lc ../peer$lc`
        cd ..

        cd $PWD/peer$lc
        echo `git remote add peer$i ../peer$i`
        cd ..
    fi
    if [[ $rc -le $num_nodes ]];then
        # echo "$i -> $rc"
        cd $PWD/peer$i
        echo `git remote add peer$rc ../peer$rc`
        cd ..

        cd $PWD/peer$rc
        echo `git remote add peer$i ../peer$i`
        cd ..
    fi
done