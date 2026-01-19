#!/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

REPOPATH=$1
NAME=$1
EMAIL=$2

# echo $REPOPATH
# echo $NAME
# echo $EMAIL

if [ -z $REPOPATH ]; then 
    echo "Empty repository path '$REPOPATH'" >&2
    exit 1
fi

if test -d $REPOPATH; then
    echo "Directory '$REPOPATH' already exists" >&2
    exit 1
fi

if [ -z $NAME ]; then
    NAME=$REPOPATH
fi

if [ -z $EMAIL ]; then
    echo "Empty email. Pass email as second argument" >&2
    exit 1
fi 

if echo "$NAME" | grep -e "[^a-zA-Z0-9]" 2>/dev/null; then
    echo "Invalid repository name '$NAME', must only contain alphanumeric characters" >&2
    exit 1 
fi

# First generate keys and store them into a tmp folder
TEMP_KEYS_PATH=$(ls /tmp | grep "p2p_client" | awk 'NR==1 {print}')

#echo "temp keys path : $TEMP_KEYS_PATH"
if [ -z "$TEMP_KEYS_PATH" ]; then
    TEMP_KEYS_PATH=$(mktemp -d /tmp/p2p_client.XXXXXX)
else
    TEMP_KEYS_PATH="/tmp/$TEMP_KEYS_PATH"
fi


ssh-keygen -t rsa -b 1024 -N "" -C "$email" -f "$TEMP_KEYS_PATH/key" -q <<< y 1>/dev/null
chmod 600 "$TEMP_KEYS_PATH/key"
chmod 644 "$TEMP_KEYS_PATH/key.pub"

shaPubKey=`cat "$TEMP_KEYS_PATH/key.pub" | sha1sum | awk '{print $1}'`
echo $shaPubKey

REPOPATH="$REPOPATH-$shaPubKey"
NAME="$NAME-$shaPubKey"

# Intialize an empty git repo
git init $REPOPATH 2>/dev/null

# Create a directory to store replica/user info.
mkdir -p $REPOPATH/.git/.author-cb

# Copy keys
cp "$TEMP_KEYS_PATH/key" $REPOPATH/.git/.author-cb/key
cp "$TEMP_KEYS_PATH/key.pub" $REPOPATH/.git/.author-cb/key.pub 

# Remove the temp keys folder
rm -rf "$TEMP_KEYS_PATH"

# Store the name of the repo/author in git-cb file
echo "$NAME" >  $REPOPATH/.git/.author-cb/git-cb

# Store the email of the author in git-cb-email file
echo "$EMAIL" >  $REPOPATH/.git/.author-cb/git-cb-email

# Create csv files in .git/.author-cb
touch $REPOPATH/.git/.author-cb/db.csv
echo "id,new_g_name,old_g_name,group_state_tree,created" > $REPOPATH/.git/.author-cb/db.csv
# fields of csv -> ("id","new_g_name","old_g_name","group_state_tree","created")
# e.g. 23212,hiking,"old_picnic_old",5a821b,"local/remote"

# Email
email=$EMAIL

# Start SSH agent
eval `ssh-agent`
ssh-add $REPOPATH/.git/.author-cb/key

# create a verifying signers
awk '{ print $3 " " $1 " " $2 }' $REPOPATH/.git/.author-cb/key.pub >> $REPOPATH/.git/.author-cb/allowed_signers

# Go inside the created git repo.
cd $REPOPATH

FULL_PATH=`pwd`
# create a config for ssh signing and verifying
git config --local user.name $NAME
git config --local user.email $email
git config --local gpg.format ssh
git config --local user.signingkey "$(cat ./.git/.author-cb/key.pub)"
git config --local gpg.ssh.allowedSignersFile $FULL_PATH/.git/.author-cb/allowed_signers
git config --local commit.gpgsign true
# git config --local log.showSignature true

# Create an empty tree
git write-tree 2>/dev/null 1>/dev/null

# Create a signed commit for storing the keys
pubKeyCommitHash=$(cat .git/.author-cb/key.pub | 
    GIT_COMMITTER_NAME="$NAME" \
    GIT_AUTHOR_NAME="$NAME" \
    GIT_COMMITTER_EMAIL="$email" \
    GIT_AUTHOR_EMAIL="$email" \
    git commit-tree -S 4b825dc642cb6eb9a060e54bf8d69288fbee4904) 


# Create a hash of author's pub-key
shaPubKey=`cat .git/.author-cb/key.pub | sha1sum | awk '{print $1}'`

git update-ref refs/heads/pubKey/$shaPubKey $pubKeyCommitHash

# Create a hook in .git/hooks/post-update, pre-receive or post-receive

echo "git-cb repo initialization successful"

# add git hook update script
cp $SCRIPTDIR/update $FULL_PATH/.git/hooks/update
cp $SCRIPTDIR/post-receive $FULL_PATH/.git/hooks/post-receive
cp $SCRIPTDIR/merge_helper.sh $FULL_PATH/.git/hooks/merge_helper.sh
cp $SCRIPTDIR/commit_helper.sh $FULL_PATH/.git/hooks/commit_helper.sh

