# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1  
fi
REMOTE=$1

if [ -z $REMOTE ]; then
    echo "Please provide remote name to push keys."
    exit 1
fi

if [ "$REMOTE" == `cat .git/.author-cb/git-cb` ];then
    echo "Can't send keys to self!"
    exit 1
fi 

remoteAvail=`git remote show $REMOTE 2>/dev/null 1>/dev/null; echo $?`

if [ $remoteAvail -ne 0 ]; then
    echo "Provided remote is not added in your repository."
    exit 1
fi

# push all keys to remote
git push $REMOTE refs/heads/pubKey/*:refs/heads/pubKey/*
if [ $? -ne 0 ]; then
    echo "Error pushing to $REMOTE"
    exit 1
fi

echo "Successfully pushed all pub-keys from local to $REMOTE"

# clear refs/remotes/pubKey/*
remotesRef=`git show-ref | grep -Ei '(/remotes/).+(/pubKey/)' | awk '{print $2}'`

for refs in $remotesRef; do
    git update-ref -d $refs
done