# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

# check if inside a valid repo
if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi


if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

# pass group name as arg 1
GROUP_NAME=$1
if [[ -z $GROUP_NAME ]];then
    echo "Please provide group name as arg 1."
    exit 1
fi

REMOTE=$2
if [[ -z $REMOTE ]];then
    echo "Please provide remote name as arg 2."
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`
if [[ "$LOCAL" == "$REMOTE" ]]; then 
    echo "Please provide the remote name to push. Not the local name"
    exit 1
fi
################### Get group info ##################
##################################################################################
# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`
# Got group id
echo "Group id is $GROUP_ID"
###################################################################################

SUB_GROUP_ID=${GROUP_ID:0:12}
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# group refs
grp_refs_str="$SUB_GROUP_ID/$sha_pubkey"

# Get group state tree object
# get_all_refs_for_group=`git show-ref | grep -E "/$SUB_GROUP_ID/"`
local_ref="refs/heads/groupConv/$grp_refs_str"
remote_ref="refs/remotes/groupConv/$grp_refs_str"
group_state_tree=`git show -s $local_ref --format="%T"`
echo "group state: $group_state_tree"

echo $local_ref
echo $remote_ref

git push $REMOTE $local_ref:$remote_ref