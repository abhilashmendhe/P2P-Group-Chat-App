#!/bin/bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

# check if inside a valid repo
if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

# Set showSignature false
git config --local log.showSignature false

# get local replica/author name
LOCAL=$(cat .git/.author-cb/git-cb)
EMAIL="$LOCAL@unibas.ch"

# Read pub-key
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# pass remote as arg 1
GROUP_NAME=$1
if [ -z $GROUP_NAME ]; then 
    echo "Please specify a group name as arg 1!"
    exit 1
fi

# group name can't be a remote replica name.
ISGROUP=`git remote show $GROUP_NAME 1>/dev/null 2>/dev/null; echo $?`
if [ $ISGROUP -eq 0 ]; then
    echo "Group name is $GROUP_NAME, which is a remote replica. Please set another group name..."
    exit 1
fi

# Give description about group
GRP_DESCRIP=$2
if [[ -z $GRP_DESCRIP ]]; then 
    echo "Please give description about the group less than 100 characters as arg 2!"
    exit 1
fi


# create a hash of sha-224 of (group_name+unix_time), then create a file of that hash
GROUP_ID=`echo -n "$GROUP_NAME$(date +%s)" | shasum -a 224 | awk {'print $1'}`
echo "Group name - $GROUP_NAME"
echo "Group Id - $GROUP_ID"


##### first add local to the group #####

# Create hash object of value 1
hashobj=`echo -n "1,1" | git hash-object --stdin -w`

# Create index to "group_name/local_peer_name"
git update-index --add --cacheinfo 100644 $hashobj $GROUP_ID/"$LOCAL"_"$sha_pubkey"

# create index to group_name
g_name_hash=`echo -n "$GROUP_NAME" | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $g_name_hash group_name

# create index to group_description
g_desc_hash=`echo -n "$GRP_DESCRIP" | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $g_desc_hash group_description

# create index to meta-version
meta_version=`echo -n "1" | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $meta_version meta_version

group_state_tree=`git write-tree`
echo "group tree hash - $group_state_tree"


# Create Message
MESSAGE="'$GROUP_NAME' group created by $LOCAL"

COMMIT_MSG="GROUP_OPS($MESSAGE,create)"
######################################################################

# Create a commit message about the created group #

# Add ssh-key
ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null


# echo "sha1sum of $LOCAL pub-key - $sha_pubkey"

# Create a signed commit for messages
pubKeyCommitHash=$(echo $COMMIT_MSG | 
    GIT_COMMITTER_NAME="$LOCAL" \
    GIT_AUTHOR_NAME="$LOCAL" \
    GIT_COMMITTER_EMAIL="$EMAIL" \
    GIT_AUTHOR_EMAIL="$EMAIL" \
    git commit-tree -S $group_state_tree) 


# insert group info in .git/.author-cb/db.csv file, and then create a file of group id.
echo "$GROUP_ID,$GROUP_NAME,"",$group_state_tree,local" >> .git/.author-cb/db.csv

# Group refs string
SUB_GROUP_ID=${GROUP_ID:0:12}
# grp_refs_str="$SUB_GROUP_ID/1/$sha_pubkey"
grp_refs_str="$SUB_GROUP_ID/$sha_pubkey"
echo $grp_refs_str

# echo "reference - refs/heads/groupConv/$grp_refs_str"
# create reference
git update-ref refs/heads/groupConv/$grp_refs_str $pubKeyCommitHash 

# remove self from update-index 
# git rm --cached $GROUP_ID/$LOCAL 1>/dev/null
git rm --cached * 

echo $MESSAGE