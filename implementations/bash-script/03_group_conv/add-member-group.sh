# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`
EMAIL="$LOCAL@unibas.ch"

# Read local pub-key
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

F_LOCAL="$LOCAL"_"$sha_pubkey"

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
    echo "Please specify remote name to add in the group!"
    exit 1
fi

# Check local repo and remote name same
if [[ "$LOCAL" == "$REMOTE" ]];then 
    echo "Can't add self to the group!!"
    # echo "You are already in the group. Can't re-add again."
    exit 1
fi

# Check if remote is your friend to add in the group
ISREMOTE=`git remote show $REMOTE 2>/dev/null 1>/dev/null; echo $?`

if [ $ISREMOTE -ne 0 ]; then 
    echo "Remote is not present in the repository"
    exit 1
fi

declare -A DUPREMOTES
REMKEYS=`git show-ref | grep -iE "pubKey" | awk -F' ' '{print $1}'`
incrr=1
for rem_key in $REMKEYS; do 
    # echo $rem_key
    trem_msg_form=`git show -s $rem_key --format="%an %B"`
    trem_name=`echo $trem_msg_form | awk -F' ' '{print $1}'`
    trem_msg_hash=`echo $trem_msg_form | awk -F' ' '{print $3}' | sha1sum | awk '{print $1}'`
    # echo $trem_name,$trem_msg_hash
    if [[ "$trem_name" == "$REMOTE" ]];then
        DUPREMOTES["$incrr"]="$trem_msg_hash"
        incrr=$((incrr+1))
    fi
done

mem_arr_len=${#DUPREMOTES[@]}
# echo "member arr len: $mem_arr_len"
if [[ $mem_arr_len -eq 0 ]];then
    echo "No remote member key found.. Can't add.."
    exit 1
fi

selected_remote=""

if [[ $mem_arr_len -eq 1 ]]; then 
    selected_remote=${DUPREMOTES[1]}
else
    for key in "${!DUPREMOTES[@]}";do 
        echo "$key> ${DUPREMOTES[$key]}"
    done

    echo "Select number from above"
    read select_remote
    selected_remote=${DUPREMOTES[$select_remote]}
    # echo "Selected remote is $selected_remote"
    if [[ -z $selected_remote ]]; then 
        echo "Selected invalid remote member to add in the group..."
        exit 1
    fi
fi
FINAL_REMOTE="$REMOTE"_"$selected_remote"

# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`

# fetch the group state tree hash of the GROUP_NAME
group_state_tree=`echo $GROUP_INFO | awk -F, '{print $4}'`

# check if you are the admin of the group or not to perform group operations
LOCAL_MEM_ALLVAL=`git cat-file -p $group_state_tree:$GROUP_ID/$F_LOCAL`
echo "Local mem all values: $LOCAL_MEM_ALLVAL"
local_member_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $1}'`
echo "Local member group present value: $local_member_val"
# echo "Local member group value : $local_member_val"
admin_causal_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $2}'`
# echo "Local member group admin value: $admin_causal_val"
echo "Admin causal value : $admin_causal_val"
# echo $is_admin
if [[ $((admin_causal_val % 2)) -eq 0 ]]; then 
    echo "You are not the admin of the group!!!"
    echo "Can't add any members!!!"
    exit 1
fi


echo "Group name - '$GROUP_NAME'"
echo "Group Id   - '$GROUP_ID'"
echo "Group tree - '$group_state_tree'"
echo "Member to add - $FINAL_REMOTE"
echo


# prechecks done
#################################################################################

######### add members in the group #########

# Check if member present inside the group
MEMBER_VALUE=`git cat-file -p $group_state_tree:$GROUP_ID/$FINAL_REMOTE 2>/dev/null`
IS_REMOTE_MEM_PRESENT=`echo $?`

if [ $IS_REMOTE_MEM_PRESENT -ne 0 ];then
    echo "$FINAL_REMOTE not present in $GROUP_NAME"
    echo "Let's add $FINAL_REMOTE in $GROUP_NAME"
    # create hash and update index
    HASH_OBJ=`echo -n "1,0" | git hash-object -w --stdin`
    git update-index --add --cacheinfo 100644 $HASH_OBJ $GROUP_ID/$FINAL_REMOTE
else 
    # echo $MEMBER_VALUE
    ind=`echo $MEMBER_VALUE | awk '{print index($0, ",")}'`
    remote_causal_val=${MEMBER_VALUE:0:ind-1}
    remote_admin_val=${MEMBER_VALUE:ind}
    # check if remote was previously removed
    if [ $((remote_causal_val % 2)) -eq 0 ]; then 
        echo "$member was previously Removed."
        echo "Will be added again..."
        remote_causal_val=$((remote_causal_val + 1))
        hash_member_val=`echo -n "$remote_causal_val,$remote_admin_val" | git hash-object -w --stdin`
        git update-index --add --cacheinfo 100644 $hash_member_val $GROUP_ID/$FINAL_REMOTE 
    else 
        echo "$FINAL_REMOTE is already in the group..."
        echo "Nothing to do."
        echo
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
        if [[ "$mem" != "$FINAL_REMOTE" ]]; then
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

# echo $meta_version
############################################################################
# write new tree and append in the file, 

# create new group conversation tree worksapce
NEW_group_state_tree=`git write-tree`

echo $group_state_tree, $NEW_group_state_tree

# Group refs string
SUB_GROUP_ID=${GROUP_ID:0:12}
grp_refs_str="$SUB_GROUP_ID/$sha_pubkey"

# create new commit for the changes
if [[ $NEW_group_state_tree != $group_state_tree ]];then
    ### create a commit about the member being added to the group ###
    # Add ssh-key
    ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null

    # create message
    MESSAGE="$FINAL_REMOTE added to group $GROUP_NAME"
    
    # get all parents ref
    PARENTS=""

    for refs in `git show-ref | grep -Ei /$SUB_GROUP_ID/ | awk '{print $1}'`; do
        PARENTS+="-p $refs "
    done

    COMMIT_MSG="GROUP_OPS($MESSAGE,add)"
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

# created_state=`echo $GROUP_INFO | awk -F, '{print $5}'`
# CSV_INFO="$GROUP_ID,$GROUP_NAME,"",$NEW_group_state_tree,$created_state"
created_state=`echo $GROUP_INFO | awk -F, '{print $5}'`
old_group_name=`echo $GROUP_INFO | awk -F, '{print $3}'`
CSV_INFO="$GROUP_ID,$GROUP_NAME,$old_group_name,$NEW_group_state_tree,$created_state"

# change that row in db.csv
sed -i "${row_num}s/.*/$CSV_INFO/" .git/.author-cb/db.csv

# remove cached index files
git rm --cached * 2>/dev/null 1>/dev/null

# # push messages to all members in the group
# PUSH=$3
# if [ ! -z $PUSH ]; then

# if [ $PUSH -eq 1 ];then
# # push messages to all members in the group
# i=0
# for member in `git show -s $NEW_group_state_tree:$GROUP_ID`; do 
#     if [ $i -lt 2 ];then
#         i+=1
#         continue
#     fi
#     if [[ $member != $LOCAL ]]; then 
#         member_val=`git show -s $NEW_group_state_tree:$GROUP_ID/$member`
#         if [ $((member_val % 2)) -eq 1 ]; then 
#             echo "Pushed to $member"
#             git push $member refs/heads/groupConv/$grp_refs_str:refs/remotes/groupConv/$grp_refs_str
#             echo
#         fi
#     fi
# done

# fi
# fi