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

num_nodes=7
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

for (( i=8; i<=11; i++)); do
    echo `$repo_init_path peer$i`
done

# Add remotes
# 4 and 8 pair
cd $PWD/peer4
echo `git remote add peer8 ../peer8`
cd ..

cd $PWD/peer8
echo `git remote add peer4 ../peer4`
cd ..

# 5 and 9 pair
cd $PWD/peer5
echo `git remote add peer9 ../peer9`
cd ..

cd $PWD/peer9
echo `git remote add peer5 ../peer5`
cd ..

# 6 and 10 pair
cd $PWD/peer6
echo `git remote add peer10 ../peer10`
cd ..

cd $PWD/peer10
echo `git remote add peer6 ../peer6`
cd ..

# 7 and 11 pair
cd $PWD/peer7
echo `git remote add peer11 ../peer11`
cd ..

cd $PWD/peer11
echo `git remote add peer7 ../peer7`
cd ..


# Create 'hiking' group in peer1, make admin to peer4 and peer9 and push it to them
cd peer1
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/create_group hiking "with family"`
cd ..
