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

# pass a message in "" as arg 2
MESSAGE=$2
if [ -z $MESSAGE 2> /dev/null ]; then
    echo "Please provide a message as arg 2 inside quotes \"\""
    exit 1
fi

# Set showSignature false
git config --local log.showSignature false

# get local replica/author name
LOCAL=$(cat .git/.author-cb/git-cb)
EMAIL="$LOCAL@unibas.ch"
# can't have self conversation
if [ "$REMOTE" == "$LOCAL" ];then
    echo "Can't have conversation with self!"
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
    echo "$REMOTE's public key not found. Can't create conversation."
    exit 1
fi

SUB_CONV_TREE=${CONV_TREE:0:7}

# Start SSH agent
ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null

# Create a hash of author's pub-key
shaPubKey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# check if already sent message to remote
LOCAL_REFS="refs/heads/conv/$SUB_CONV_TREE/$shaPubKey"
REMOTE_REFS="refs/remotes/conv/$SUB_CONV_TREE/$shaPubKey"
LOCAL_REMOTE_REFS="refs/remotes/conv/$SUB_CONV_TREE/$REMOTE_PUBKEY_HASH"

# echo "Local refs $LOCAL_REFS"
# echo "Remote refs $REMOTE_REFS"
# echo "Local-remote refs $LOCAL_REMOTE_REFS"

# check if the local conv present or not
IS_CONV_PRESENT=`git show -s $LOCAL_REFS 1>/dev/null 2>/dev/null; echo $?`

# parents
PARENTS=""

if [ $IS_CONV_PRESENT -eq 0 ];then
    # echo "Conversation present. This is the conv-tree id: $CONV_TREE"  
    PARENTS+="-p $LOCAL_REFS"
fi

# check if the remote conv present or not
IS_REMOTE_CONV_PRESENT=`git show -s $LOCAL_REMOTE_REFS 1>/dev/null 2>/dev/null; echo $?`
if [ $IS_REMOTE_CONV_PRESENT -eq 0 ];then 
    # PARENTS+="-p $LOCAL_REFS"
    # echo "Conversation with '$REMOTE' already present!!"
    PARENTS+=" -p $LOCAL_REMOTE_REFS"
fi

# echo "Parents are:"
# echo $PARENTS

# Create a signed commit for messages
pubKeyCommitHash=$(echo $MESSAGE | 
    GIT_COMMITTER_NAME="$LOCAL" \
    GIT_AUTHOR_NAME="$LOCAL" \
    GIT_COMMITTER_EMAIL="$EMAIL" \
    GIT_AUTHOR_EMAIL="$EMAIL" \
    git commit-tree -S $CONV_TREE $PARENTS)

echo 
echo "Message: '$MESSAGE' was created by '$LOCAL' for '$REMOTE'."
echo "commit-message hash: $pubKeyCommitHash."
echo 
# Create a reference
git update-ref $LOCAL_REFS $pubKeyCommitHash

# echo "'$MESSAGE' for '$REMOTE' created in workspace tree - $CONV_TREE"

# # Before pushing ping for the remote if available and then push
# #--- ping code ----

# to push to remote
PUSH=$3
if [ -z $PUSH ];then
    # echo "Not pushing"
    exit 1
fi
if [ $PUSH -eq 1 ];then
    $SCRIPTDIR/push-single-conv.sh $REMOTE
fi

