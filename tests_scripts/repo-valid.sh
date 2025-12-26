#!/usr/bin/env bash

REPOPATH=$1
if [ -z $REPOPATH ]; then 
    echo "Empty repository path '$REPOPATH'" >&2
    exit 1
fi

if ! test -d $REPOPATH/.git; then
    echo "Invalid Git repository at $REPOPATH" >&2
    exit 1
fi

if ! test -f $REPOPATH/.git/.author-cb/git-cb; then
    echo "Invalid git-cb repository at $REPOPATH, missing 'git-cb' file" >&2
    exit 1
fi

if ! test -f $REPOPATH/.git/.author-cb/key; then
    echo "Invalid git-cb repository at $REPOPATH, missing private key." >&2
    exit 1
fi

if ! test -f $REPOPATH/.git/.author-cb/key.pub; then
    echo "Invalid git-cb repository at $REPOPATH, missing public key." >&2
    exit 1
fi

PRIVKEY=`ssh-keygen -y -e -f .git/.author-cb/key`
PUBKEY=`ssh-keygen -y -e -f .git/.author-cb/key.pub`

if [[ "$PRIVKEY" != "$PUBKEY" ]];then 
    echo "Private and Public keys are not a key-pair."
    exit 1
fi
