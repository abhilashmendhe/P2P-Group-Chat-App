# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`
EMAIL="$LOCAL@unibas.ch"

# Set showSignature false
git config --local log.showSignature false

# pass group name as arg 1
GROUP_NAME=$1
# pass remote name as arg 2
REMOTE=$2

if [ -z $GROUP_NAME ]; then 
    echo "Please specify a group name as arg 1!"
    exit 1
fi

ISGROUP=`git remote show $GROUP_NAME 1>/dev/null 2>/dev/null; echo $?`
if [ $ISGROUP -eq 0 ]; then
    echo "Group name is '$GROUP_NAME', which is a remote replica."
    echo "Please specify a valid existing group name."
    exit 1
fi

# Check if remote arg passed
if [ -z $REMOTE ]; then 
    echo "Please specify remote name to make the admin of the group!"
    exit 1
fi

# Check local repo and remote name same
if [[ "$LOCAL" == "$REMOTE" ]];then 
    echo "You are trying to become admin of this group. Not allowed!!"
    echo "Ask the admin of the group to make you as the admin!!"
    exit 1
fi

# Check if remote is your friend to add in the group
ISREMOTE=`git remote show $REMOTE 2>/dev/null 1>/dev/null; echo $?`

if [ $ISREMOTE -ne 0 ]; then 
    echo "Remote is not present in the repository"
    exit 1
fi

# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# Read pub-key
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`

# fetch the group state tree hash of the GROUP_NAME
group_state_tree=`echo $GROUP_INFO | awk -F, '{print $4}'`

echo "Fetched group state: $group_state_tree"

# check if you are the admin of the group or not to perform group operations
LOCAL_MEM_ALLVAL=`git cat-file -p $group_state_tree:$GROUP_ID/$LOCAL`
echo "Local mem all values: $LOCAL_MEM_ALLVAL"
local_member_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $1}'`
echo "Local member group present value: $local_member_val"

admin_causal_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $2}'`
echo "Local member group admin value: $admin_causal_val"
# echo $is_admin
if [[ $((admin_causal_val % 2)) -eq 0 ]]; then 
    echo "You are not the admin of the group!!!"
    echo "Can't make other members as admin!!!"
    exit 1
fi

IS_MEMBER_PRESENT=`git cat-file -p $group_state_tree:$GROUP_ID/$REMOTE 2>/dev/null`
echo "Remote causal all value: $IS_MEMBER_PRESENT"
if [[ -z $IS_MEMBER_PRESENT ]]; then 
    echo "Member is not in the group. Can't do this operation."
    echo "Please provide a valid member that is in the group to make admin."
    exit 1
fi

remote_member_val=`echo $IS_MEMBER_PRESENT | awk -F, '{print $1}'`
echo "Remote causal group value: $remote_member_val"

if [[ $((remote_member_val % 2)) -eq 0 ]];then
    echo "Member is not in the group. Can't do this operation."
    echo "Please provide a valid member that is in the group to make admin."
    exit 1
fi

admin_remote_causal_val=`echo $IS_MEMBER_PRESENT | awk -F, '{print $2}'`
echo "Remote causal admin value: $admin_remote_causal_val"

if [[ $((admin_remote_causal_val % 2)) -eq 1 ]]; then
    echo "Member is already an admin. Can't do this operation."
    exit 1
fi  

echo "Group name - '$GROUP_NAME'"
echo "Group Id   - '$GROUP_ID'"
echo "Group tree - '$group_state_tree'"
echo "Member to make admin - $REMOTE"
echo


# prechecks done
#################################################################################

# add the remote in group state tree
admin_remote_new_causal_value=$((admin_remote_causal_val + 1))
remote_new_full_value="$remote_member_val,$admin_remote_new_causal_value"
# echo $remote_new_full_value
hash_remote_new_full_value=`echo -n $remote_new_full_value | git hash-object --stdin`
git update-index --add --cacheinfo 100644 $hash_remote_new_full_value $GROUP_ID/$REMOTE

# re-add existing member to create tree and check if already present
MEMBERS=`git cat-file -p $group_state_tree:$GROUP_ID`
prev_hash=""
i=1
for mem in $MEMBERS; do 
    if [[ "$mem" == "100644" || "$mem" == "blob" ]];then 
        continue
    fi
    if [[ $((i % 2)) -eq 0 ]];then
        if [[ "$mem" != "$REMOTE" ]]; then
            # echo $mem
            git update-index --add --cacheinfo 100644 $prev_hash $GROUP_ID/$mem
        fi
    else 
        prev_hash=$mem
    fi
    i=$((i + 1))
done 

# also add the group_name in index tree
g_name_hash=`echo -n $GROUP_NAME | git hash-object --stdin`
git update-index --add --cacheinfo 100644 $g_name_hash group_name

# also add the group_description in index tree
g_desc_hash=`git cat-file -p $group_state_tree | grep -E "group_description" | awk '{print $3}'`
git update-index --add --cacheinfo 100644 $g_desc_hash group_description

# create index to meta-version
meta_version=`git cat-file -p $group_state_tree | grep -E "meta_version" | awk '{print $3}'`
git update-index --add --cacheinfo 100644 $meta_version meta_version


############################################################################
# write new tree and append in the file, 

# create new group conversation tree worksapce
NEW_group_state_tree=`git write-tree`

echo "New group state - $NEW_group_state_tree"

# Group refs string
SUB_GROUP_ID=${GROUP_ID:0:12}
grp_refs_str="$SUB_GROUP_ID/$sha_pubkey"

# create new commit for the changes
if [[ $NEW_group_state_tree != $group_state_tree ]];then
    ### create a commit about the member being added to the group ###
    # Add ssh-key
    ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null

    # create message
    MESSAGE="$REMOTE was made admin to this $GROUP_NAME"
    
    # get all parents ref
    PARENTS=""

    for refs in `git show-ref | grep -Ei /$SUB_GROUP_ID/ | awk '{print $1}'`; do
        PARENTS+="-p $refs "
    done

    COMMIT_MSG="GROUP_OPS($MESSAGE,make_admin)"
    # Create a signed commit for messages
    pubKeyCommitHash=$(echo $COMMIT_MSG | 
        GIT_COMMITTER_NAME="$LOCAL" \
        GIT_AUTHOR_NAME="$LOCAL" \
        GIT_COMMITTER_EMAIL="$EMAIL" \
        GIT_AUTHOR_EMAIL="$EMAIL" \
        git commit-tree -S $NEW_group_state_tree $PARENTS) 

    # echo "reference - refs/heads/groupConv/$grp_refs_str"
    git update-ref refs/heads/groupConv/$grp_refs_str $pubKeyCommitHash 
fi

created_state=`echo $GROUP_INFO | awk -F, '{print $5}'`
old_group_name=`echo $GROUP_INFO | awk -F, '{print $3}'`
CSV_INFO="$GROUP_ID,$GROUP_NAME,$old_group_name,$NEW_group_state_tree,$created_state"
# change that row in db.csv
sed -i "${row_num}s/.*/$CSV_INFO/" .git/.author-cb/db.csv

# remove cached index files
git rm --cached * 2>/dev/null 1>/dev/null


