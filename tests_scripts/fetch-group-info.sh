#!/bin/bash

GROUP_NAME=$1
################### Get group info ##################
GROUP_INFO=`cat .git/.author-cb/db.csv | grep -nE ",$GROUP_NAME,"`

if [[ -z $GROUP_INFO ]];then 
    echo "Group '$GROUP_NAME' does not exists!"
    # echo "Can't add any members!"
    exit 1
fi

# check multiple groups and select one by input
i=0
flag=0
for inf in $GROUP_INFO; do
    if [[ $i -gt 0 ]]; then 
        flag=1    
        break
    fi
    i=$((i+1))
done

if [[ $flag -eq 1 ]]; then 
    
    r_nums=""
    for inf in $GROUP_INFO; do
        r_nums+="${inf:0:1} "
        echo "${inf:0:1} => ${inf:2}" 
    done
    echo
    echo "Please select the row number to perform operation on that group"
    read row_num

    flag=0
    for row in $r_nums;do
        if [[ $row_num -eq $row ]]; then 
            flag=1
            break
        fi
    done

    if [[ $flag -ne 1 ]];then
        echo "You didn't select the correct group to send message!"
        exit 1
    fi

    GROUP_INFO=`awk "NR==$row_num" .git/.author-cb/db.csv`
else
    IND_COLON=`echo $GROUP_INFO | awk '{print index($0, ":")}'`
    row_num=${GROUP_INFO:0:IND_COLON-1}
    GROUP_INFO=${GROUP_INFO:IND_COLON}
fi
