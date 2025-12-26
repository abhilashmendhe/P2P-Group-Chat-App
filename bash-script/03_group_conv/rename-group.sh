#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

# get local peer info
LOCAL=`cat .git/.author-cb/git-cb`
EMAIL="$LOCAL@unibas.ch"

# Set showSignature false
git config --local log.showSignature false

# pass group name as arg 1
GROUP_NAME=$1

if [ -z $GROUP_NAME ];then 
    echo "Please enter the group name!"
    exit 1
fi

NEW_GROUP_NAME=$2

if [ -z $NEW_GROUP_NAME ]; then
    echo "New group name not provided. Please provide the group name."
    exit 1
fi

NEW_GROUP_DESC=$3
if [[ -z $NEW_GROUP_DESC ]]; then
    echo "Please pass the group description too!"
    exit 1
fi

echo $NEW_GROUP_NAME
echo $NEW_GROUP_DESC


# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# Read pub-key
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`

# fetch the group state tree hash of the GROUP_NAME
group_state_tree=`echo $GROUP_INFO | awk -F, '{print $4}'`

OLD_GROUP_DESC=`git cat-file -p $group_state_tree:group_description`

if [[ "$GROUP_NAME" == "$NEW_GROUP_NAME" && "$OLD_GROUP_DESC" == "$NEW_GROUP_DESC" ]]; then 
    echo "Old group name and New group name are same!"
    echo "Old group description and New group description are same!"
    echo "Can't change!!!"
    exit 1
fi

# echo "Ready to modify group name and description"

# check if you are the admin of the group or not to perform group operations
LOCAL_MEM_ALLVAL=`git cat-file -p $group_state_tree:$GROUP_ID/$LOCAL`
echo "Local mem all values: $LOCAL_MEM_ALLVAL"
local_member_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $0}'`
echo "Local member group present value: $local_member_val"

admin_causal_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $1}'`
echo "Local member group admin value: $admin_causal_val"

# echo $is_admin
if [[ $((admin_causal_val % 2)) -eq 0 ]]; then 
    echo "You are not the admin of the group!!!"
    echo "Can't rename the group!!!"
    exit 1
fi

echo "Group name - '$GROUP_NAME'"
echo "Group Id   - '$GROUP_ID'"
echo "Group tree - '$group_state_tree'"
echo

#                       # prechecks done #                        #


# echo "New group name: $NEW_GROUP_NAME"

# re-add existing member to create tree and check if already present
MEMBERS=`git cat-file -p $group_state_tree:$GROUP_ID`
prev_hash=""
i=1
for mem in $MEMBERS; do 
    if [[ "$mem" == "100644" || "$mem" == "blob" ]];then 
        continue
    fi
    if [[ $((i % 2)) -eq 0 ]];then
        # if [[ "$mem" != "$REMOTE" ]]; then
            # echo $mem
        git update-index --add --cacheinfo 100644 $prev_hash $GROUP_ID/$mem
        # fi
    else 
        prev_hash=$mem
    fi
    i=$((i + 1))
done

# create hash object for new group name
GROUP_NAME_HASH=`echo -n $NEW_GROUP_NAME | git hash-object --stdin -w`
# echo $GROUP_NAME_HASH
# add the gropu name index in tree
git update-index --add --cacheinfo 100644 $GROUP_NAME_HASH "group_name"


# create hash object for new group description
GROUP_DESC_HASH=`echo -n $NEW_GROUP_DESC | git hash-object --stdin -w`
# also add the group_description in index tree
git update-index --add --cacheinfo 100644 $GROUP_DESC_HASH group_description

# update the meta_version (increment the meta version value by 1)
meta_version=`git cat-file -p $group_state_tree:meta_version`
meta_version=$((meta_version+1))
meta_version_hash=`echo -n $meta_version | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $meta_version_hash meta_version
# echo "meta_version: $meta_version ,  $meta_version_hash"

# create new conv tree
NEW_group_state_tree=`git write-tree`
echo "new group state tree : $NEW_group_state_tree"

# Group refs string
SUB_GROUP_ID=${GROUP_ID:0:12}
grp_refs_str="$SUB_GROUP_ID/$sha_pubkey"


# create new commit for the changes
if [[ $NEW_group_state_tree != $group_state_tree ]];then
    ### create a commit about the member being added to the group ###
    # Add ssh-key
    ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null

    # create message
    MESSAGE="Group name changed from '$GROUP_NAME' to '$NEW_GROUP_NAME'"
    
    # get all parents ref
    PARENTS=""
    # PARENTS="-p refs/heads/groupConv/$SUB_GROUP_ID/$GROUP_CONV_VERSION/$sha_pubkey -p refs/remotes/groupConv/$SUB_GROUP_ID/$GROUP_CONV_VERSION/$sha_pubkey"

    for refs in `git show-ref | grep -Ei /$SUB_GROUP_ID/ | awk '{print $1}'`; do
        PARENTS+="-p $refs "
    done
    # echo $PARENTS

    COMMIT_MSG="GROUP_OPS($MESSAGE,rename)"

    # Create a signed commit for messages
    pubKeyCommitHash=$(echo $COMMIT_MSG | 
        GIT_COMMITTER_NAME="$LOCAL" \
        GIT_AUTHOR_NAME="$LOCAL" \
        GIT_COMMITTER_EMAIL="$EMAIL" \
        GIT_AUTHOR_EMAIL="$EMAIL" \
        git commit-tree -S $NEW_group_state_tree $PARENTS) 


    # echo "Commit hash - $pubKeyCommitHash"
    git update-ref refs/heads/groupConv/$grp_refs_str $pubKeyCommitHash
fi


created_state=`echo $GROUP_INFO | awk -F, '{print $5}'`
CSV_INFO="$GROUP_ID,$NEW_GROUP_NAME,"old_$GROUP_NAME",$NEW_group_state_tree,$created_state"

# change that row in db.csv
sed -i "${row_num}s/.*/$CSV_INFO/" .git/.author-cb/db.csv

# remove cached index files
git rm --cached * 2>/dev/null 1>/dev/null

# # PUSH=$3
# # if [[ ! -z $PUSH ]];then
# # if [[ $PUSH -eq 1 ]];then
# # # push messages to all members in the group, to odd values
# # i=0
# # for member in `git show -s $NEW_TREE_CONV:$GROUP_ID`; do 
# #     if [ $i -lt 2 ];then
# #         i+=1
# #         continue
# #     fi
# #     if [[ $member != $LOCAL ]]; then 
# #         member_val=`git show -s $NEW_TREE_CONV:$GROUP_ID/$member`
# #         if [ $((member_val % 2)) -eq 1 ]; then 
# #             echo "Pushed to $member"
# #             git push $member refs/heads/groupConv/$grp_refs_str:refs/remotes/groupConv/$grp_refs_str
# #             echo
# #         fi
# #     fi
# # done    
# # fi
# # fi