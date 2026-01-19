# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

# check if inside a valid repo
if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

# export createConv function from create-conv.sh file
source $SCRIPTDIR/create-conv.sh

# pass remote as arg 1
REMOTE=$1
if [ -z $REMOTE ]; then 
    echo "Please specify a remote as arg 1 to send the message!"
    exit 1
fi

# Set showSignature false
git config --local log.showSignature false

# get local replica/author name
LOCAL=$(cat .git/.author-cb/git-cb)
EMAIL="$LOCAL@unibas.ch"
# can't have self conversation
if [ "$REMOTE" == "$LOCAL" ];then
    echo "Can't push your own conversation to yourself!"
    exit 1
fi

# check if remote exists before sending a message
git remote show $REMOTE 1>/dev/null 2>/dev/null;
if [ $? -ne 0 ]; then
    echo "Remote not added to your repo. Please add the remote first!"
    exit 1
fi

# call createConv to create a conversation
read -r CONV_TREE REMOTE_PUBKEY_HASH <<< "$( createConv $LOCAL $REMOTE )"

# CONV_TREE=`createConv $REMOTE`
if [ -z $CONV_TREE ];then
    echo "No conversation with '$REMOTE' found!"
    exit 1
fi

SUB_CONV_TREE=${CONV_TREE:0:7}

# Create a hash of author's pub-key
shaPubKey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

REF="refs/heads/conv/$SUB_CONV_TREE/$shaPubKey"
CONV_PRESENT=`git show -s $REF 2>/dev/null 1>/dev/null; echo $?`

if [[ $CONV_PRESENT -ne 0 ]]; then
    echo "No conversation with '$REMOTE' found!"
    exit 1
fi

echo "Conversation with '$REMOTE' found!"
echo "Pushing chats to '$REMOTE'"

REMOTE_REF="refs/remotes/conv/$SUB_CONV_TREE/$shaPubKey"
git push $REMOTE $REF:$REMOTE_REF