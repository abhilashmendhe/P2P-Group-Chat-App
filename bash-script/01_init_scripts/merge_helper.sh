# curr_group_state=$1
# local_group_state=$1

# declare a hashmap name 'curr_members'
declare -A curr_members
curr_g_id=$g_id

i=0
f1=0
total_members_curr=0
for member in `git show -s $curr_group_state:$curr_g_id`; do
    if [[ $i -lt 2 ]]; then
        i=$((i + 1))
        continue
    fi
    total_members_curr=$((total_members_curr+1))
    curr_c_val=`git show -s $curr_group_state:$curr_g_id/$member 2>/dev/null`
    curr_c_admin=`echo $curr_c_val | awk -F, '{print $2}'`
    if [[ $((curr_c_admin % 2)) -eq 1 ]];then 
        f1=1
    fi
    curr_members[$member]=$curr_c_val
done

i=0
f2=0
total_members_old=0
for member in `git show -s $local_group_state:$curr_g_id`; do
    if [[ $i -lt 2 ]]; then
        i=$((i + 1))
        continue
    fi
    total_members_old=$((total_members_old+1))
    # echo $member
    old_c_val=`git show -s $local_group_state:$curr_g_id/$member 2>/dev/null`
    
    hm_c_val=${curr_members[$member]}
    if [[ ! -z $hm_c_val ]]; then 
        # echo "$member prsent in hashmap"
        hm_c_ingroup=`echo $hm_c_val | awk -F, '{print $1}'`
        hm_c_admin=`echo $hm_c_val | awk -F, '{print $2}'`
        old_c_ingroup=`echo $old_c_val | awk -F, '{print $1}'`
        old_c_admin=`echo $old_c_val | awk -F, '{print $2}'`

        if [[ $hm_c_ingroup -ge $old_c_ingroup ]]; then 
            merge_c_ingroup=$hm_c_ingroup
        else 
            merge_c_ingroup=$old_c_ingroup
        fi

        if [[ $hm_c_admin -ge $old_c_admin ]]; then
            merge_c_admin=$hm_c_admin
        else 
            merge_c_admin=$old_c_admin
        fi
        if [[ $((merge_c_admin % 2)) -eq 1 ]]; then 
            f2=1
        fi
        merge_c_val="$merge_c_ingroup,$merge_c_admin"
        curr_members[$member]=$merge_c_val
    else
        curr_members[$member]=$old_c_val
    fi
done

# max_members=$(( total_members_curr > total_members_old ? total_members_curr : total_members_old ))
echo "max members : $max_members"
atleast_admin=0
if [[ $f1 -eq 1 || $f2 -eq 1 ]]; then 
    atleast_admin=1
fi

if [[ $atleast_admin -eq 1 ]]; then 
    echo "Atleast one admin present. No need to make other members admin"
    for c_member in "${!curr_members[@]}"; do 
        new_causal_val=${curr_members[$c_member]}
        # echo "$c_member - $new_causal_val with id: $curr_g_id"  
        new_hash_causal_val=`echo -n $new_causal_val | git hash-object --stdin -w`
        git update-index --add --cacheinfo 100644 $new_hash_causal_val $curr_g_id/$c_member
    done
else
    echo "No admin is there in the group." 
    # echo "Group members are more than 2. Make everyone admin."
    for c_member in "${!curr_members[@]}"; do 
        new_causal_val=${curr_members[$c_member]}
        # echo "$c_member - $new_causal_val with id: $curr_g_id" 
        new_c_member_val=`echo $new_causal_val | awk -F, '{print $1}'`
        new_c_admin_val=`echo $new_causal_val | awk -F, '{print $2}'` 
        if [[ $(( new_c_member_val % 2 )) -eq 1 ]]; then

            if [[ $(( new_c_admin_val % 2 )) -eq 0 ]]; then 
                new_c_admin_val=$((new_c_admin_val + 1))
            fi
            new_causal_val="$new_c_member_val,$new_c_admin_val"
        fi
        new_hash_causal_val=`echo -n $new_causal_val | git hash-object --stdin -w`
        git update-index --add --cacheinfo 100644 $new_hash_causal_val $curr_g_id/$c_member
    done
fi

# Now check for both group name and descrtion by comparing the meta_version
recv_meta_version=`git show -s $curr_group_state:meta_version`
local_meta_version=`git show -s $local_group_state:meta_version`

new_g_name=""
new_g_desc=""
new_g_meta=""

if [ $recv_meta_version -gt $local_meta_version ]; then 
    # echo "recv bigger"
    new_g_name=`git cat-file -p $curr_group_state:group_name`
    new_g_desc=`git cat-file -p $curr_group_state:group_description`
    new_g_meta=`git cat-file -p $curr_group_state:meta_version`
elif [ $local_meta_version -gt $recv_meta_version ]; then 

    new_g_name=`git cat-file -p $local_group_state:group_name`
    new_g_desc=`git cat-file -p $local_group_state:group_description`
    new_g_meta=`git cat-file -p $local_group_state:meta_version`
else
    echo "same"
    name1=`git cat-file -p $curr_group_state:group_name`
    name2=`git cat-file -p $local_group_state:group_name`
    desc1=`git cat-file -p $curr_group_state:group_description`
    desc2=`git cat-file -p $local_group_state:group_description`

    h1=`echo -n $name1$desc1 | git hash-object --stdin`
    h2=`echo -n $name2$desc2 | git hash-object --stdin`
    
    if [[ "$h1" > "$h2" ]]; then 
        new_g_name=$name1
        new_g_desc=$desc1
    elif [[ "$h2" > "$h2" ]]; then
        new_g_name=$name2
        new_g_desc=$desc2
    else 
        new_g_name=$name1
        new_g_desc=$desc1
    fi 

    new_g_meta=$recv_meta_version
fi

# # also add the group_name in index tree
new_g_name_hash=`echo -n $new_g_name | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $new_g_name_hash group_name

# also add the group_description in index tree
new_g_desc_hash=`echo -n $new_g_desc | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $new_g_desc_hash group_description

# also add the meta_version in index tree
new_g_meta_hash=`echo -n $new_g_meta | git hash-object --stdin -w`
git update-index --add --cacheinfo 100644 $new_g_meta_hash meta_version

new_group_state_tree=`git write-tree`
echo "In merge_helper.sh, new group state - $new_group_state_tree"

git rm --cached group_name 1>/dev/null
git rm --cached group_description 1>/dev/null
git rm --cached meta_version 1>/dev/null
git rm --cached $curr_g_id/* 1>/dev/null