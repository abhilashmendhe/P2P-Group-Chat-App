# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

if ! $SCRIPTDIR/../repo-valid.sh '.'; then
    exit 1
fi

# turn off show signature
git config --local log.showSignature false

KEYS=`git show-ref | grep refs/heads/pubKey/ | awk '{print $1}'`

for k in $KEYS; do 
    added=`git log $k --format="%G?"`
    if [[ "$added" != "G" ]];
    then
        MSG=`git log $k --format="%B"`
        echo $MSG | awk '{ print $3 " " $1 " " $2 }' >> .git/.author-cb/allowed_signers
    fi
done
# turn on show signature
git config --local log.showSignature true

echo "All keys added successfully"

# clear refs/remotes/pubKey/*
remotesRef=`git show-ref | grep -Ei '(/remotes/).+(/pubKey/)' | awk '{print $2}'`
for refs in $remotesRef; do
    git update-ref -d $refs
done