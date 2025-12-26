#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

G_NAME=$1
if [[ -z "$G_NAME" ]]; then 
    echo "Pass group name as first argument."
    exit 1
fi

# Create 'hiking' group in peer1, make admin to peer4 and peer9 and push it to them
cd peer1

echo `$SCRIPTDIR/../_2_group_ops_api/target/release/create_group $G_NAME "with family"`

# Add peer4 and peer9
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/add_member $G_NAME peer4`
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/add_member $G_NAME peer9`


# Promote peer4 and peer9
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/promote $G_NAME peer4`
echo `$SCRIPTDIR/../_2_group_ops_api/target/release/promote $G_NAME peer9`

# Push to peer4
echo `$SCRIPTDIR/../tests_scripts/push-group-single.sh $G_NAME peer4`

sleep .5

# Push to peer9
echo `$SCRIPTDIR/../tests_scripts/push-group-single.sh $G_NAME peer9`