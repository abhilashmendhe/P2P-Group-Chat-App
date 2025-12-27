#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

repo_init_path="$SCRIPTDIR/../_1_repo_init/target/release/repo_init"
# echo "$repo_init_path"


START=1
END=11


for i in $(seq $START $END); do
    echo `$repo_init_path peer$i`
    # echo "peer$i"
done

totalpeers=$((END-START+1))
echo "Total peers: $totalpeers"

# echo "4 neighbors"
for k in 1 3 8 $((totalpeers-1)); do
    for i in $(seq 1 $totalpeers); do 
        rempeer=$(( (i + $k) % $totalpeers ))
        
        cd peer$i
        if [[ $rempeer == 0 ]]; then 
            # echo "$i -> $totalpeers"
            git remote add peer$totalpeers ../peer$totalpeers
        else 
            # echo "$i -> $rempeer"
            git remote add peer$rempeer ../peer$rempeer
        fi
        cd ../
    done
done

echo "Creating group 'hiking'"
sleep 1

# Create 'hiking' group in peer1, make admin to peer4 and peer9 and push it to them
cd peer1
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/create_group hiking "with family"`

# Add peer4 and peer9
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/add_member hiking peer4`
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/add_member hiking peer9`


# Promote peer4 and peer9
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/promote hiking peer4`
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/promote hiking peer9`

# Push to peer4
echo `$SCRIPTDIR/../tests_scripts/push-group-single.sh hiking peer4`

sleep .5

# Push to peer9
echo `$SCRIPTDIR/../tests_scripts/push-group-single.sh hiking peer9`

