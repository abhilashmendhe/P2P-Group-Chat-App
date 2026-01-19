# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

LOCAL=`cat .git/.author-cb/git-cb`
for refs in $(git show-ref | awk '{print $2}'); do 
    
    is_verify=`git log $refs --format="%G?"`
    if [ "$is_verify" == "U" ];then
        git_msg=`git log $refs --format="%B" | awk '{ print $3 " " $1 " " $2 }'`
        echo $git_msg >> .git/.author-cb/allowed_signers
        verify=`git log $refs --format="%G?"`

        if [ "$verify" != "G" ]; then 
            author=`git log $refs --format="%an"`
            echo "$author didn't send a valid public key. Removing it!"
            filename=".git/.author-cb/allowed_signers"
            file_size="$(stat --format=%s "$filename")"
            trim_count="$(tail -n1 "$filename" | wc -c)"
            end_position=$(($file_size - $trim_count))
            dd if=/dev/null of="$filename" bs=1 seek="$end_position"
            git update-ref -d refs
        fi
    fi
done


echo "All keys have been verified!!"

# # clear refs/remotes/pubKey/*
# remotesRef=`git show-ref | grep -Ei '(/remotes/).+(/pubKey/)' | awk '{print $2}'`

# for refs in $remotesRef; do
#     git update-ref -d $refs
# done
