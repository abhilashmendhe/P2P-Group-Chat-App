#!/bin/bash

TEST_AREA=./test_area

cd $TEST_AREA

# pwd
REPO_INIT=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_1_repo_init/target/release/repo_init
CREATE_GROUP=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release/create_group
ADD_MEMBER_GROUP=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release/add_member
REMOVE_MEMBER_GROUP=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release/remove_member
PROMOTE_GROUP=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release/promote
DEMOTE_GROUP=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release/demote
RENAME_GROUP=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release/rename_group
PUSH_GROUP=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/scripts/push-group-single.sh
GET_GROUP_MSG=/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/functional_testing/get-group-info.sh



################################## 1. Add same member ##################################
# clear all test_area
rm -rf ./*
$REPO_INIT alice "alice@gmail.com" $2> /dev/null
$REPO_INIT bob "bob@gmail.com" $2> /dev/null

cd ./alice 
git remote add bob ../bob $2> /dev/null
$CREATE_GROUP hiking "with phds" $2> /dev/null
g_id=`cat .git/.author-cb/db.csv | tail -n 1 | awk -F',' '{print $1}'`
# echo "Group id: $g_id"
$ADD_MEMBER_GROUP hiking bob $2> /dev/null
$PROMOTE_GROUP hiking bob $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null
$ADD_MEMBER_GROUP hiking carol $2> /dev/null

cd ../bob 
git remote add alice ../alice
$ADD_MEMBER_GROUP hiking carol $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "1. Add same member ✅"
else 
    echo "1. Add same member ❌"
fi

################################## 2. Remove same members then merge ##################################
cd ../alice
$REMOVE_MEMBER_GROUP hiking carol $2> /dev/null
cd ../bob
$REMOVE_MEMBER_GROUP hiking carol $2> /dev/null

cd ../alice
$PUSH_GROUP hiking bob $2> /dev/null
cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "2. Remove same members then merge  ✅"
else 
    echo "2. Remove same members then merge  ❌"
fi

cd ..

################################## 3. Add two different members then merge ##################################
# clear all test_area
rm -rf ./*
$REPO_INIT alice "alice@gmail.com" $2> /dev/null
$REPO_INIT bob "bob@gmail.com" $2> /dev/null

cd ./alice 
git remote add bob ../bob $2> /dev/null
$CREATE_GROUP hiking "with phds" $2> /dev/null
g_id=`cat .git/.author-cb/db.csv | tail -n 1 | awk -F',' '{print $1}'`
# echo "Group id: $g_id"
$ADD_MEMBER_GROUP hiking bob $2> /dev/null
$PROMOTE_GROUP hiking bob $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null
$ADD_MEMBER_GROUP hiking carol $2> /dev/null

cd ../bob 
git remote add alice ../alice
$ADD_MEMBER_GROUP hiking eve $2> /dev/null

# exchange
$PUSH_GROUP hiking alice $2> /dev/null
cd ../alice
$PUSH_GROUP hiking bob $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "3. Add two different members then merge ✅"
else 
    echo "3. Add two different members then merge ❌"
fi


################################## 4. Remove two different members then merge ##################################
# echo $PWD
$REMOVE_MEMBER_GROUP hiking carol $2> /dev/null
cd ../bob
$REMOVE_MEMBER_GROUP hiking eve $2> /dev/null

cd ../alice
$PUSH_GROUP hiking bob $2> /dev/null
cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "4. Remove two different members then merge  ✅"
else 
    echo "4. Remove two different members then merge  ❌"
fi

cd ..
# cd ..

################################## 5. Remove member + Member exit ##################################
# clear all test_area
rm -rf ./*
$REPO_INIT alice "alice@gmail.com" $2> /dev/null
$REPO_INIT bob "bob@gmail.com" $2> /dev/null

cd ./alice 
git remote add bob ../bob $2> /dev/null
$CREATE_GROUP hiking "with phds" $2> /dev/null
g_id=`cat .git/.author-cb/db.csv | tail -n 1 | awk -F',' '{print $1}'`
# echo "Group id: $g_id"
$ADD_MEMBER_GROUP hiking bob $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob 
git remote add alice ../alice

cd ../alice
$REMOVE_MEMBER_GROUP hiking bob $2> /dev/null
cd ../bob
$REMOVE_MEMBER_GROUP hiking bob $2> /dev/null

cd ../alice
$PUSH_GROUP hiking bob $2> /dev/null
cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "5. Remove member + Member exit ✅"
else 
    echo "5. Remove member + Member exit ❌"
fi

cd ..
# cd ..

################################## 6. Promote same member ##################################
# clear all test_area
rm -rf ./*
$REPO_INIT alice "alice@gmail.com" $2> /dev/null
$REPO_INIT bob "bob@gmail.com" $2> /dev/null

cd ./alice 
git remote add bob ../bob $2> /dev/null
$CREATE_GROUP hiking "with phds" $2> /dev/null
g_id=`cat .git/.author-cb/db.csv | tail -n 1 | awk -F',' '{print $1}'`
# echo "Group id: $g_id"
$ADD_MEMBER_GROUP hiking bob $2> /dev/null
$PROMOTE_GROUP hiking bob $2> /dev/null
$ADD_MEMBER_GROUP hiking carol $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob 
git remote add alice ../alice
$PROMOTE_GROUP hiking carol  $2> /dev/null

cd ../alice
$PROMOTE_GROUP hiking carol  $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "6. Promote same member ✅"
else 
    echo "6. Promote same member ❌"
fi

cd ..

################################## 7. Demote same member ##################################

cd ./alice
$DEMOTE_GROUP hiking carol  $2> /dev/null

cd ../bob 
$DEMOTE_GROUP hiking carol  $2> /dev/null

cd ../alice
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "7. Demote same member ✅"
else 
    echo "7. Demote same member ❌"
fi

cd ..

################################## 8. Promote two different members ##################################
# clear all test_area
rm -rf ./*
$REPO_INIT alice "alice@gmail.com" $2> /dev/null
$REPO_INIT bob "bob@gmail.com" $2> /dev/null

cd ./alice 
git remote add bob ../bob $2> /dev/null
$CREATE_GROUP hiking "with phds" $2> /dev/null
g_id=`cat .git/.author-cb/db.csv | tail -n 1 | awk -F',' '{print $1}'`
# echo "Group id: $g_id"
$ADD_MEMBER_GROUP hiking bob $2> /dev/null
$PROMOTE_GROUP hiking bob $2> /dev/null
$ADD_MEMBER_GROUP hiking carol $2> /dev/null
$ADD_MEMBER_GROUP hiking eve $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob 
git remote add alice ../alice
$PROMOTE_GROUP hiking carol  $2> /dev/null

cd ../alice
$PROMOTE_GROUP hiking eve  $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "8. Promote two different members ✅"
else 
    echo "8. Promote two different members ❌"
fi

cd ..

################################## 9. Demote two different members ##################################

cd ./alice
$DEMOTE_GROUP hiking eve  $2> /dev/null

cd ../bob 
$DEMOTE_GROUP hiking carol  $2> /dev/null

cd ../alice
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "9. Demote two different members ✅"
else 
    echo "9. Demote two different members ❌"
fi

cd ..

################################## 10. Demote each others + Members ##################################
# clear all test_area
rm -rf ./*
$REPO_INIT alice "alice@gmail.com" $2> /dev/null
$REPO_INIT bob "bob@gmail.com" $2> /dev/null

cd ./alice 
git remote add bob ../bob $2> /dev/null
$CREATE_GROUP hiking "with phds" $2> /dev/null
g_id=`cat .git/.author-cb/db.csv | tail -n 1 | awk -F',' '{print $1}'`
# echo "Group id: $g_id"
$ADD_MEMBER_GROUP hiking bob $2> /dev/null
$PROMOTE_GROUP hiking bob $2> /dev/null
$ADD_MEMBER_GROUP hiking carol $2> /dev/null
$ADD_MEMBER_GROUP hiking eve $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob 
git remote add alice ../alice
$DEMOTE_GROUP hiking alice  $2> /dev/null

cd ../alice
$DEMOTE_GROUP hiking bob  $2> /dev/null
$PUSH_GROUP hiking bob $2> /dev/null

cd ../bob
$PUSH_GROUP hiking alice $2> /dev/null

BOB_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $BOB_MSG_SHA

cd ../alice
ALICE_MSG_SHA=`$GET_GROUP_MSG $g_id | sha1sum | awk -F' ' '{print $1}'`
# echo $ALICE_MSG_SHA
if [[ $ALICE_MSG_SHA == $BOB_MSG_SHA ]]; then 
    echo "10. Demote each others + Members ✅"
else 
    echo "10. Demote each others + Members ❌"
fi

cd ..