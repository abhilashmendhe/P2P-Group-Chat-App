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

keyHash=""
if [ "$ALLKEYS" != "*" ]; then
    keyHash=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`
    localKeyRef=$(git show-ref refs/heads/pubKey/$keyHash)
    if [ -z "$localKeyRef" ]; then
        echo "Your local public key reference not found. Unable to push to $REMOTE"
        exit 1
    fi 
fi

# push your local key to remote
# git push $REMOTE refs/heads/pubKey/$keyHash:refs/remotes/$REMOTE/pubKey/$keyHash 
git push $REMOTE refs/heads/pubKey/$keyHash:refs/heads/pubKey/$keyHash

if [ $? -ne 0 ]; then
    echo "Error pushing to $REMOTE. Please ping the remote repository."
    exit 1
fi

echo "Successfully pushed your local key to $REMOTE"
# to check diff between two string variables
# diff <(echo "$str1") <(echo "$str2") | echo $?
# if diff then output is 1 else 0

# clear refs/remotes/pubKey/*
remotesRef=`git show-ref | grep -Ei '(/remotes/).+(/pubKey/)' | awk '{print $2}'`
for refs in $remotesRef; do
    git update-ref -d $refs
done