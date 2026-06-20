# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

echo "SCRIPTDIR - $SCRIPTDIR"

# check if inside a valid repo
if ! $SCRIPTDIR/repo-valid.sh '.'; then
    exit 1
fi

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

echo $SCRIPTDIR

# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`

SUB_GROUP_ID=${GROUP_ID:0:12}
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

local_ref="refs/heads/groupConv/$SUB_GROUP_ID/$sha_pubkey"
local_remote_ref="refs/remotes/groupConv/$SUB_GROUP_ID/$sha_pubkey"
output=$(GIT_PROGRESS_DELAY=0 \
git -c pack.useStderr=false \
    -c core.progress=true \
    push --progress $REMOTE $local_ref:$local_remote_ref 2>&1)
# echo $output >> $PWD/file.log
echo $output