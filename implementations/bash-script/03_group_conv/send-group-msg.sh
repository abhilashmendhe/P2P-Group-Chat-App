# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`
EMAIL="$LOCAL@unibas.ch"

# Set showSignature false
git config --local log.showSignature false

# pass remote as arg 1
GROUP_NAME=$1
if [ -z $GROUP_NAME ]; then 
    echo "Please specify a group name as arg 1!"
    exit 1
fi

ISGROUP=`git remote show $GROUP_NAME 1>/dev/null 2>/dev/null; echo $?`
if [ $ISGROUP -eq 0 ]; then
    echo "Group name is $GROUP_NAME, which is a remote replica. Please set another group name..."
    exit 1
fi

MESSAGE=$2

if [[ -z $MESSAGE ]]; then
    echo "Please specify a message as arg 2!"
    exit 1
fi

# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# echo $GROUP_INFO
########################################################################
eval `ssh-agent`
# Read pub-key
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`

# fetch the group state tree hash of the GROUP_NAME
group_state_tree=`echo $GROUP_INFO | awk -F, '{print $4}'`


# echo
echo "Group name - '$GROUP_NAME'"
echo "Group Id   - '$GROUP_ID'"
echo "Group tree - '$group_state_tree'"
echo "Message    - \"$MESSAGE\""
# echo "Group Version - '$GROUP_CONV_VERSION'"
echo

# check if you can send the message in group
# first get the member value from group
LOCAL_MEM_VAL=`git show -s $group_state_tree:$GROUP_ID/$LOCAL`
MEM_VAL_IND=`echo $LOCAL_MEM_VAL | awk '{print index($0,",")}'`
IN_GROUP=${LOCAL_MEM_VAL:0:MEM_VAL_IND-1}

# echo $IN_GROUP
if [ $((IN_GROUP % 2)) -eq 0 ];then
    echo "You are not in the group. Can't send any messages"
    exit 1
fi

# Add ssh-key
ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null

# get sub_group id
SUB_GROUP_ID=${GROUP_ID:0:12}

PARENTS=""
for group_ref in `git show-ref | grep -iE /$SUB_GROUP_ID/ | awk '{print $1}'`; do
    PARENTS+=" -p $group_ref"
done
# echo $PARENTS

# Group refs string
# grp_refs_str="${GROUP_NAME}/${group_state_tree:0:5}/$sha_pubkey"
# grp_refs_str="${GROUP_NAME}/$sha_pubkey"
# grp_refs_str="$SUB_GROUP_ID/$GROUP_CONV_VERSION/$sha_pubkey"
grp_refs_str="$SUB_GROUP_ID/$sha_pubkey"

COMMIT_MSG="MSG($MESSAGE)"
# Create a signed commit for messages
pubKeyCommitHash=$(echo $COMMIT_MSG | 
    GIT_COMMITTER_NAME="$LOCAL" \
    GIT_AUTHOR_NAME="$LOCAL" \
    GIT_COMMITTER_EMAIL="$EMAIL" \
    GIT_AUTHOR_EMAIL="$EMAIL" \
    git commit-tree -S $group_state_tree $PARENTS) 

# print commit hash
echo "Commit Message hash - $pubKeyCommitHash"

# update group message ref
git update-ref refs/heads/groupConv/$grp_refs_str $pubKeyCommitHash

# # PUSH=$3
# # if [ ! -z $PUSH ]; then

# # if [ $PUSH -eq 1 ];then
# # # push messages to all members in the group
# # i=0
# # for member in `git show -s $group_state_tree:$GROUP_ID`; do 
# #     if [ $i -lt 2 ];then
# #         i+=1
# #         continue
# #     fi
# #     if [[ $member != $LOCAL ]]; then 
# #         member_val=`git show -s $group_state_tree:$GROUP_ID/$member`
# #         if [ $((member_val % 2)) -eq 1 ]; then 
# #             echo "Pushed to $member"
# #             git push $member refs/heads/groupConv/$grp_refs_str:refs/remotes/groupConv/$grp_refs_str
# #             echo
# #         fi
# #     fi
# # done
# # fi

# # fi
