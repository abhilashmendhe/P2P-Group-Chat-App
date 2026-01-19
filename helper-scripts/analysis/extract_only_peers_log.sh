#!/bin/bash

fpath=$1

if [[ -z $fpath ]]; then 
    echo "Please pass first argument either 'push' or 'pull' or 'pull-push'"
    exit 1
fi

if [[ "$fpath" != "push" && "$fpath" != "pull" && "$fpath" != "pull-push" ]]; then 
    echo "First arg should be 'push' or 'pull' or 'pull-push'"
    exit 1
fi

cd ../$fpath

for k in {1..4}; do 
    # echo $ks
    cd k$k
    for i in {1..11}; do 
        cd peer$i
        touch peer$i\_commits.log
        pwd
        logout=`git log  $(git show-ref | grep groupConv | awk -F' ' '{print $1}') --author=$(cat .git/.author-cb/git-cb) --no-show-signature --oneline --format="%h %t %ct" --reverse`
        echo -e "$logout" > peer$i\_commits.log
        cd ..
    done
    echo 
    cd ..
done
