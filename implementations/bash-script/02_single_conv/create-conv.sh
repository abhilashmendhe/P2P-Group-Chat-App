# !/usr/bin/env bash

function createConv() {
    local LOCAL=$1
    local REMOTE=$2
    local FLAG=0
    # Set showSignature false
    git config --local log.showSignature false

    # hash of the local pub key
    local LOCAL_HASH=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

    # hash of the remote pub key
    local REMOTE_HASH=""
    local keyRefs=`git show-ref | grep -Ei /pubKey/ | awk '{print $1}'`
    for ref in $keyRefs; do
        remote=`git log $ref --format="%cn"`
        pubkey=`git log $ref --format="%B"`
        if [[ "$REMOTE" == "$remote" ]];then
            REMOTE_HASH=`echo $pubkey | sha1sum | awk '{print $1}'`
            FLAG=1
        fi
    done
    if [ $FLAG -eq 0 ];then
        return 1
    fi
    # echo "Local  hash is $LOCAL_HASH"
    # echo "Remote hash is $REMOTE_HASH"

    # create empty object
    # local empty_obj=`echo "" | git hash-object --stdin -w`
    local l_obj=`echo -n "$LOCAL" | git hash-object --stdin -w`
    local r_obj=`echo -n "$REMOTE" | git hash-object --stdin -w`
    
    # add remote hash for indexing
    git update-index --add --cacheinfo 100644 $l_obj $LOCAL_HASH
    git update-index --add --cacheinfo 100644 $r_obj $REMOTE_HASH

    local CONV_TREE=`git write-tree`

    # delete cached files
    git rm --cached * 1>/dev/null 2>/dev/null

    echo $CONV_TREE $REMOTE_HASH
}

# read -r A B <<< "$( createConv carol )"
# echo $A 
# echo $B 