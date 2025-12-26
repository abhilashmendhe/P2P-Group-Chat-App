#!/bin/bash

echo "!!!!Merge Ops commit performing!!!!"
old_commit_msg=`git show -s $newrev --format="%B"`
sub_old_commit_msg=${old_commit_msg:9}
# sub_g_id=${curr_g_id:0:12}
echo $sub_g_id

grp_refs_str="$sub_g_id/$sha_pubkey"

ssh-add .git/.author-cb/key 1>/dev/null 2>/dev/null

# get all parents ref
PARENTS=""
for refs in `git show-ref | grep -iE "/$sub_g_id/" | awk '{print $1}'`; do
    # echo $refs
    PARENTS+="-p $refs "
done

# new commit message
NEW_COMMIT_MSG="MERGE_OPS$sub_old_commit_msg"

# Create a signed commit for messages
pubKeyCommitHash=$(echo $NEW_COMMIT_MSG | 
    GIT_COMMITTER_NAME="$LOCAL" \
    GIT_AUTHOR_NAME="$LOCAL" \
    GIT_COMMITTER_EMAIL="$EMAIL" \
    GIT_AUTHOR_EMAIL="$EMAIL" \
    git commit-tree -S $new_group_state_tree $PARENTS) 

echo "new commit message for merge ops at $LOCAL: $pubKeyCommitHash"
# echo "reference - refs/heads/groupConv/$grp_refs_str"
git update-ref refs/heads/groupConv/$grp_refs_str $pubKeyCommitHash