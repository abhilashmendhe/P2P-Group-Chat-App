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

# Fetch group information
source $SCRIPTDIR/fetch-group-info.sh

# Read pub-key
sha_pubkey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

# fetch group id of the GROUP_NAME
GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`

# fetch the group state tree hash of the GROUP_NAME
group_state_tree=`echo $GROUP_INFO | awk -F, '{print $4}'`

# print information
echo "Group name - '$GROUP_NAME'"
echo "Group Id   - '$GROUP_ID'"
echo "Group tree - '$group_state_tree'"
echo

# check if you are the admin of the group or not to perform group operations
LOCAL_MEM_ALLVAL=`git cat-file -p $group_state_tree:$GROUP_ID/$LOCAL`
# echo "Local mem all values: $LOCAL_MEM_ALLVAL"

local_member_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $0}'`
# echo "Local member group present value: $local_member_val"

# check if local present in the group, if not don't proceed further
if [[ $((local_member_val % 2)) -eq 0 ]]; then 
    echo "You are already not in the group!!"
    echo "Cant' exit group '$GROUP_NAME'!!"
    exit 1
fi

admin_causal_val=`echo $LOCAL_MEM_ALLVAL | awk -F, '{print $1}'`
# echo "Local member group admin value: $admin_causal_val"

local_member_val=$((local_member_val + 1))

# check for atleast one admin
atleast_one_admin=0
MEMBERS=`git show -s $group_state_tree:$GROUP_ID`
# echo $MEMBERS
j=0
for mem in $MEMBERS; do
    if [[ $j -lt 2 || "$mem" == "$LOCAL" ]];then 
        j=$((j+1))
        continue
    fi 
    m_val=`git show -s $group_state_tree:$GROUP_ID/$mem`
    # echo $mem - $m_val
    m_in_group_val=`echo $m_val | awk -F, '{print $1}'`
    m_admin_val=`echo $m_val | awk -F, '{print $2}'`
    if [[ $((m_admin_val % 2)) -eq 1 ]]; then 
        atleast_one_admin=1
        break
    fi
done

# add local to the group state tree
admin_causal_val=$((admin_causal_val + 1))
new_local_mem_allvalue="$local_member_val,$admin_causal_val"
new_local_hash_mem_allvalue=`echo -n $new_local_mem_allvalue | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $new_local_hash_mem_allvalue $GROUP_ID/$LOCAL

# echo $atleast_one_admin
if [[ $((admin_causal_val % 2)) -eq 1 && $atleast_one_admin -eq 0 ]]; then 
    echo "You are the admin of the group!!!"
    echo "If you exit, all the other members become the admin"
    
    # now re-add all members but also make everyone admin
    MEMBERS=`git show -s $group_state_tree:$GROUP_ID`
    # echo $MEMBERS
    j=0
    for mem in $MEMBERS; do
        if [[ $j -lt 2 || "$mem" == "$LOCAL" ]];then 
            j=$((j+1))
            continue
        fi 
        m_val=`git show -s $group_state_tree:$GROUP_ID/$mem`
        # echo $mem - $m_val
        m_in_group_val=`echo $m_val | awk -F, '{print $1}'`
        m_admin_val=`echo $m_val | awk -F, '{print $2}'`
        if [[ $((m_in_group_val%2)) -eq 1 ]]; then 
            if [[ $((m_admin_val % 2 )) -eq 0 ]]; then 
                m_admin_val=$((m_admin_val + 1))
                m_val="$m_in_group_val,$m_admin_val"
            fi
        fi
        # echo $new_m_val
        new_m_val_hash=`echo -n $m_val | git hash-object --stdin -w`
        # echo $new_m_val_hash
        git update-index --add --cacheinfo 100644 $new_m_val_hash $GROUP_ID/$mem
    done
    # exit 1
else

    # re-add existing member to create tree and check if already present
    MEMBERS=`git cat-file -p $group_state_tree:$GROUP_ID`
    prev_hash=""
    i=1
    for mem in $MEMBERS; do 
        # echo $mem
        if [[ "$mem" == "100644" || "$mem" == "blob" ]];then 
            continue
        fi
        if [[ $((i % 2)) -eq 0 ]];then
            if [[ "$mem" != "$LOCAL" ]]; then
                # echo $mem - $prev_hash
                git update-index --add --cacheinfo 100644 $prev_hash $GROUP_ID/$mem
            fi
        else 
            prev_hash=$mem
        fi
        i=$((i + 1))
    done 

fi

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

    # # create message
    # MESSAGE="$REMOTE added to group $GROUP_NAME"
    # create message
    MESSAGE="$LOCAL exited group, '$GROUP_NAME'"
    
    # get all parents ref
    PARENTS=""

    for refs in `git show-ref | grep -Ei /$SUB_GROUP_ID/ | awk '{print $1}'`; do
        PARENTS+="-p $refs "
    done

    COMMIT_MSG="GROUP_OPS($MESSAGE,exit)"
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

echo
echo $CSV_INFO
echo "Row num: $row_num"
echo
# change that row in db.csv
sed -i "${row_num}s/.*/$CSV_INFO/" .git/.author-cb/db.csv

# remove cached index files
git rm --cached * 2>/dev/null 1>/dev/null


