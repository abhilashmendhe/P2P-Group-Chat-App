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
    echo "Group name is $GROUP_NAME, which is a remote replica. Please specify a valid existing group name."
    exit 1
fi


# Check if remote arg passed
if [ -z $REMOTE ]; then 
    echo "Please specify remote name to remove from  the group!"
    exit 1
fi

EXITING=0

# Check local repo and remote name same
if [[ "$LOCAL" == "$REMOTE" ]];then 
    # echo "Can't remove self from the '$GROUP_NAME' group."
    # echo "If you want to exit the group, please run 'exit-group.sh' script."
    # echo "$LOCAL, you will exit the group..."
    EXITING=1
    # exit 1
fi

if [ $EXITING -eq 0 ];then
    # Check if remote is your friend to add in the group
    ISREMOTE=`git remote show $REMOTE 2>/dev/null 1>/dev/null; echo $?`

    if [ $ISREMOTE -ne 0 ]; then 
        echo "Remote is not present in the repository"
        exit 1
    fi
fi


# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# Read pub-key
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`

# fetch the group state tree hash of the GROUP_NAME
group_state_tree=`echo $GROUP_INFO | awk -F, '{print $4}'`


# check if you are the admin of the group or not to perform group operations
LOCAL_MEM_ALLVAL=`git cat-file -p $group_state_tree:$GROUP_ID/$LOCAL`
echo "Local mem CRDT tuple value: $LOCAL_MEM_ALLVAL"

local_member_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $1}'`
echo "Local member group present value: $local_member_val"

admin_causal_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $2}'`
echo "Local member group admin value: $admin_causal_val"

echo "Group name - '$GROUP_NAME'"
echo "Group Id   - '$GROUP_ID'"
echo "Group tree - '$group_state_tree'"
if [ $EXITING -eq 0 ]; then
    echo "Member to remove - $REMOTE"
else
    echo "Member to exit - $LOCAL"
fi
echo

###################################################################################
# # FIRST_COMMIT_HASH=`git rev-list --max-parents=0 `
# # LATEST_COMMIT_HASH=`git log <hash>/<ref> -1`
# # prechecks done
# #################################################################################



if [ $EXITING -eq 1 ]; then 
    ##### Exit group code #####

    if [[ $((local_member_val % 2)) -eq 0 ]]; then 
        echo "$LOCAL - You are not inside the group, can't exit!"
        exit 1
    fi
    if [[ $((admin_causal_val % 2)) -eq 1 ]]; then 
        admin_causal_val=$((admin_causal_val + 1))
    fi
    local_member_val=$((local_member_val + 1))
    hash_member_val=`echo -n "$local_member_val,$admin_causal_val" | git hash-object --stdin -w`
    # echo "new hash member: $hash_member_val"
    # echo "$remote_causal_val, $remote_admin_val"
    git update-index --add --cacheinfo 100644 $hash_member_val $GROUP_ID/$REMOTE

else 
    ######### remove members from the group code #########
    # first check if local is admin or not
    if [[ $((admin_causal_val % 2)) -eq 0 ]]; then 
        echo "You are not the admin of the group!!!"
        echo "Can't remove any members!!!"
        exit 1
    fi

    # # Check if remote member present inside the group
    MEMBER_VALUE=`git cat-file -p $group_state_tree:$GROUP_ID/$REMOTE 2>/dev/null`
    IS_MEM_PRESENT=`echo $?`

    if [ $IS_MEM_PRESENT -eq 0 ];then
        # echo "$REMOTE present in $GROUP_NAME"
        # echo "Its' blob value: $MEMBER_VALUE"
        # check if already removed or not..
        ind=`echo $MEMBER_VALUE | awk '{print index($0, ",")}'`
        remote_causal_val=${MEMBER_VALUE:0:ind-1}
        remote_admin_val=${MEMBER_VALUE:ind}
        if [ $((remote_causal_val % 2)) -eq 1 ]; then 
            echo "$REMOTE is actually there right now in the group: $GROUP_NAME. Let's remove it."
            # check if remote is admin. If admin, make the admin value to even, i.e it's now non-admin
            # and will be removed from the group
            if [[ $((remote_admin_val % 2)) -eq 1 ]]; then
                remote_admin_val=$((remote_admin_val + 1))
            fi
            remote_causal_val=$((remote_causal_val + 1))
            hash_member_val=`echo -n "$remote_causal_val,$remote_admin_val" | git hash-object --stdin -w`
            # echo "new hash member: $hash_member_val"
            # echo "$remote_causal_val, $remote_admin_val"
            git update-index --add --cacheinfo 100644 $hash_member_val $GROUP_ID/$REMOTE
        else
            echo "$REMOTE was already removed from the group $GROUP_NAME."
            echo "Nothing to do."
            exit 1
        fi
    else 
        echo "'$REMOTE' not present in the '$GROUP_NAME' group. Nothing to remove"
        exit 1
    fi
fi


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

################### Create New gropu state tree, Commit and Push to existing members #######################

# # Create new tree
NEW_group_state_tree=`git write-tree`
echo "New conv. tree - $NEW_group_state_tree"

# Group refs string
SUB_GROUP_ID=${GROUP_ID:0:12}
grp_refs_str="$SUB_GROUP_ID/$sha_pubkey"

if [[ $NEW_group_state_tree != $group_state_tree ]];then

    ### create a commit about the member being removed to the group ###
    # Add ssh-key
    ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null

    # create message
    if [ $EXITING -eq 0 ]; then 
        MESSAGE="$REMOTE removed from group '$GROUP_NAME'"
    else 
        MESSAGE="$LOCAL exited from group '$GROUP_NAME'"
    fi
    # get all parents ref
    PARENTS=""
    # PARENTS="-p refs/heads/groupConv/$SUB_GROUP_ID/$GROUP_CONV_VERSION/$sha_pubkey -p refs/remotes/groupConv/$SUB_GROUP_ID/$GROUP_CONV_VERSION/$sha_pubkey"

    for refs in `git show-ref | grep -Ei /$SUB_GROUP_ID/ | awk '{print $1}'`; do
        PARENTS+="-p $refs "
    done

    COMMIT_MSG="GROUP_OPS($MESSAGE,remove)"
    # Create a signed commit for messages
    pubKeyCommitHash=$(echo $COMMIT_MSG | 
        GIT_COMMITTER_NAME="$LOCAL" \
        GIT_AUTHOR_NAME="$LOCAL" \
        GIT_COMMITTER_EMAIL="$EMAIL" \
        GIT_AUTHOR_EMAIL="$EMAIL" \
        git commit-tree -S $NEW_group_state_tree $PARENTS) 


    echo "Commit hash - $pubKeyCommitHash"
    # echo "reference - refs/heads/groupConv/$grp_refs_str"
    git update-ref refs/heads/groupConv/$grp_refs_str $pubKeyCommitHash 
fi

# created_state=`echo $GROUP_INFO | awk -F, '{print $5}'`
# CSV_INFO="$GROUP_ID,$GROUP_NAME,"",$NEW_group_state_tree,$created_state"
created_state=`echo $GROUP_INFO | awk -F, '{print $5}'`
old_group_name=`echo $GROUP_INFO | awk -F, '{print $3}'`
CSV_INFO="$GROUP_ID,$GROUP_NAME,$old_group_name,$NEW_group_state_tree,$created_state"

# change that row in db.csv
sed -i "${row_num}s/.*/$CSV_INFO/" .git/.author-cb/db.csv

# remove cached index files
git rm --cached * 2>/dev/null 1>/dev/null

