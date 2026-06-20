#!/bin/bash

SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/repo-valid.sh '.'; then
    exit 1
fi

# # # pass group name as arg 1
# # GROUP_NAME=$1
# # if [[ -z $GROUP_NAME ]];then
# #     echo "Please provide group name as arg 1."
# #     exit 1
# # fi
# ################### Get group info ##################
# #####################################################

# WITH_MESSAGE=$1

# all_groups=`cat .git/.author-cb/db.csv`

# i=0
# for gr in $all_groups; do
#     if [[ $i -lt 1 ]];then
#         i=$((i + 1))
#         continue
#     fi
#     g_id=`echo $gr | awk -F, '{print $1}'`
#     g_name=`echo $gr | awk -F, '{print $2}'`
#     sub_g_id=${g_id:0:12}
#     echo "$i. $g_name ($sub_g_id)"
#     i=$((i + 1))
# done

# if [[ $i -lt 2 ]]; then 
#     echo "No groups found to display."
#     exit 1
# fi
# echo
# echo "Enter the row number to select the group to check the information."
# read row_num

# clear 

# LOCAL_MEMBER=`cat .git/.author-cb/git-cb`

# #echo -e "$LOCAL_MEMBER"
# echo -e "\033[1;92m$LOCAL_MEMBER\033[0m"
# echo "----------------------------------"
# #printf "\e[48;5;%dm%03d $LOCAL_MEMBER 209" printf '\e[0m \n'
# if [[ $row_num -ge $i ]]; then 
#     echo "You did now provide the exact row number to get the group."
#     exit 1
# fi

# row_num=$((row_num + 1))
# GROUP_INFO=`awk "NR==$row_num" .git/.author-cb/db.csv`

# # echo $GROUP_INFO
# GROUP_ID=`echo $GROUP_INFO | awk -F, '{print $1}'`
GROUP_ID=$1
SUB_GROUP_ID=${GROUP_ID:0:12}

# echo $SUB_GROUP_ID
#commits_hash=`git show-ref | grep -E "/$SUB_GROUP_ID/" | awk '{print $1}'`
commits_hash=`git show-ref | grep -E "/$SUB_GROUP_ID/" | grep -E heads | awk '{print $1}'`
group_state_tree=`git show -s $commits_hash --format="%T" -1 | tail -n 1`

# echo $commits_hash
g_name=`git cat-file -p $group_state_tree:group_name`
g_desc=`git cat-file -p $group_state_tree:group_description`

members=""
admins=""
removed=""
ind=0
for member in `git show -s $group_state_tree:$GROUP_ID`; do 
    if [[ $ind -lt 2 ]];then 
        ind=$((ind + 1))
        continue
    fi
    member_val=`git show -s $group_state_tree:$GROUP_ID/$member`
    # echo $member_val
    comma_ind=`echo $member_val | awk '{print index($0, ",")}'`
    is_member=${member_val:0:comma_ind-1}
    is_admin=${member_val:comma_ind}
    
    if [[ $((is_member % 2)) -eq 1 ]]; then
        members+="$member, "
	if [[ $((is_admin % 2 )) -eq 1 ]]; then
            admins+="$member, "
    	fi
    else 
        removed+="$member, "
    fi
    #if [[ $((is_admin % 2 )) -eq 1 ]]; then 
    #    admins+="$member, "
    #fi
done

g_heading="\033[1;94m$g_name\033[0m ($SUB_GROUP_ID) ['\033[4;96m$g_desc\033[0m']"
echo
echo -e $g_heading
echo
echo "Members - $members"
echo
echo "Admins - $admins"
echo
echo "Removed Members - $removed"
echo

# echo "Sub group id: $SUB_GROUP_ID"
# group_show_ref=`git show-ref | grep $SUB_GROUP_ID`
# echo $group_show_ref
echo $WITH_MESSAGE
if [[ -z $WITH_MESSAGE ]];then
    exit 0
fi
######
# Set colors
######
ALICE='\e[38;5;8m'
BOB='\e[31m'
CAROL='\e[32m'
DEN='\e[33m'
EVA='\e[34m'
FARAH='\e[35m'
GREG='\e[36m'
HENRY='\e[37m'
RESET='\e[0m'

join_commit_ids=""
i=0
for values in `git show-ref | grep $SUB_GROUP_ID`; do 
    if [[ $((i % 2)) -eq 0 ]]; then 
        # echo "$values"
        join_commit_ids+="$values "
    fi
    i=$((i + 1))
done

# for msgs in `git log $join_commit_ids --topo-order --reverse --pretty=format:"Author: %an%nMessage: %s%n"`; do 
#     echo $msgs
# done
#

echo "Messages"
echo "--------------------------------------------"
echo ""
{ git log --no-show-signature $join_commit_ids --pretty=format:"%an|%B" --topo-order --reverse; echo; } | while IFS='|' read -r author message; do
    
    if [[ ! -z $author ]];then
        if [[ "$message" == *"GROUP_OPS"* ]]; then
            # echo "$author: $message" "group ops"
            first_part=$(echo "$message" | cut -d',' -f1)
            second_word=$(echo "$message" | cut -d',' -f2 | awk '{print $1}')
            # echo "$first_part"
            # echo "$author: ${first_part:10}"
            if [[ "$author" == "alice" ]];then 
                echo -e "${ALICE}$author${RESET}: ${first_part:10}"
            elif [[ "$author" == "bob" ]];then
                echo -e "${BOB}$author${RESET}: ${first_part:10}"
            elif [[ "$author" == "carol" ]];then
                echo -e "${CAROL}$author${RESET}: ${first_part:10}"
            elif [[ "$author" == "den" ]];then
                echo -e "${DEN}$author${RESET}: ${first_part:10}"
            elif [[ "$author" == "eva" ]];then
                echo -e "${EVA}$author${RESET}: ${first_part:10}"
            elif [[ "$author" == "farah" ]];then
                echo -e "${FARAH}$author${RESET}: ${first_part:10}"
            elif [[ "$author" == "greg" ]];then
                echo -e "${GREG}$author${RESET}: ${first_part:10}"
            elif [[ "$author" == "henry" ]];then
                echo -e "${HENRY}$author${RESET}: ${first_part:10}"
            else 
                echo "$author: ${first_part:10}"
            fi
        elif [[ "$message" == *"MSG"* ]]; then
            content=$(echo "$message" | sed -E 's/^MSG\((.*)\)$/\1/')
            # echo "$author: $content"
            if [[ "$author" == "alice" ]];then 
                echo -e "${ALICE}$author${RESET}: $content"
            elif [[ "$author" == "bob" ]];then 
                echo -e "${BOB}$author${RESET}: $content"
            elif [[ "$author" == "carol" ]];then 
                echo -e "${CAROL}$author${RESET}: $content"
            elif [[ "$author" == "den" ]];then 
                echo -e "${DEN}$author${RESET}: $content"
            elif [[ "$author" == "eva" ]];then 
                echo -e "${EVA}$author${RESET}: $content"
            elif [[ "$author" == "farah" ]];then 
                echo -e "${FARAH}$author${RESET}: $content"
            elif [[ "$author" == "greg" ]];then 
                echo -e "${GREG}$author${RESET}: $content"
            else 
                echo "$author: $content"
            fi
        fi
    fi
done

echo ""
