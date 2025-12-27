#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

repo_init_path="$SCRIPTDIR/../_1_repo_init/target/release/repo_init"
# echo "$repo_init_path"

neighbors=$1

if [[ -z $neighbors ]]; then 
    echo "Please pass the first argument between 1-4"
    exit 1
fi

if [[ $neighbors < 1 || $neighbors > 4 ]]; then 
    echo "Argument should be between 1-4"
    exit 1
fi

for i in {1..7}; do
    echo `$repo_init_path peer$i`
done
totalpeers=7
if [[ $neighbors == 1 ]]; then 
    # echo "Only 1 neighbor"
    for i in {1..7}; do 
        rempeer=$(( (i+1)%$totalpeers ))
        
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
elif [[ $neighbors == 2 ]]; then 
    # echo "2 neighbors"
    for k in 1 2; do
        for i in {1..7}; do 
            rempeer=$(( (i + $k) % $totalpeers ))
            cd peer$i
            if [[ $rempeer == 0 ]]; then 
                # echo "$i -> $totalpeers"
                git remote add peer$totalpeers ../peer$totalpeers
            else 
                git remote add peer$rempeer ../peer$rempeer
            fi
            cd ../
        done
    done
elif [[ $neighbors == 3 ]]; then 
    # echo "3 neighbors"
    for k in 1 2 5; do
        for i in {1..7}; do 
            rempeer=$(( (i + $k) % $totalpeers ))
            cd peer$i
            if [[ $rempeer == 0 ]]; then 
                # echo "$i -> $totalpeers"
                git remote add peer$totalpeers ../peer$totalpeers
            else 
                git remote add peer$rempeer ../peer$rempeer
            fi
            cd ../
        done
    done
elif [[ $neighbors == 4 ]]; then 
    # echo "4 neighbors"
    for k in 1 2 5 6; do
        for i in {1..7}; do 
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
fi

echo "Creating group 'hiking'"
sleep 1

# Create 'hiking' group in peer1, make admin to peer3 and peer6 and push it to them
cd peer1
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/create_group hiking "with family"`

# Add peer3 and peer6
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/add_member hiking peer3`
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/add_member hiking peer6`


# Promote peer3 and peer6
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/promote hiking peer3`
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/promote hiking peer6`

# Push to peer3
echo `$SCRIPTDIR/../tests_scripts/push-group-single.sh hiking peer3`

sleep 1

# Push to peer6
echo `$SCRIPTDIR/../tests_scripts/push-group-single.sh hiking peer6`

