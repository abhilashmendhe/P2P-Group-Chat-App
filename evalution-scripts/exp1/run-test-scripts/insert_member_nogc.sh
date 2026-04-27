# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

# echo $SCRIPTDIR
# echo $PWD

size4="10240"
# size4="16"

REPO_INIT_PATH="/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_1_repo_init/target/release/repo_init"
GROUP_OPS_PATH="/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release"

GROUP_NAME="hiking"
GROUP_DESC="With my friends family etccc"


member_size=$size4
mili=1000000000


# Insert members of member_size without gc
# create peers
echo `$REPO_INIT_PATH peer-$member_size-nogc`
echo `$REPO_INIT_PATH peer-$member_size-remote-nogc`

cd peer-$member_size-nogc
git remote add peer-$member_size-remote-nogc ../peer-$member_size-remote-nogc
git config gc.auto 0
git config gc.autoPackLimit 0
touch "push-group-$member_size-nogc.log"
echo "add-mem-time,dif-add-mem-time,push-time,dif-push-time,git-size,count,size,in-pack,packs,size-pack,prune-packable,garbage,size-garbage,None" >  "data-group-$member_size-nogc.csv"

# Create group
$GROUP_OPS_PATH/create_group $GROUP_NAME $GROUP_DESC

gitsize=`du -s --block-size=1 ".git/objects" | awk -F' ' '{print $1}'`
dcc=`git count-objects -v |
awk '
BEGIN { OFS="," }
{
    gsub(":", "", $1)
    printf "%s,", $2
    sep=","
}
END { print "" }
'`
tstart=$(date +%s%N)
echo $tstart,0,0,0,$gitsize,$dcc >> "data-group-$member_size-nogc.csv"

for ((i=1; i<=$member_size; i++));do 

    # Add member
    start=$(date +%s%N)
    $GROUP_OPS_PATH/add_member $GROUP_NAME "peer$i"
    end=$(date +%s%N)
    diff=$(($end-$start))
    time_diff_res=$(echo "scale=10; $diff/$mili" | bc)

    # Push member
    pu_start=$(date +%s%N)
    res=`$SCRIPTDIR/../tests_scripts/push-group-single.sh $GROUP_NAME peer-$member_size-remote-nogc`
    echo $res | sed 's/\r/\n/g' \
                | grep -E 'done\.|To |remote:' \
                >> "push-group-$member_size-nogc.log"
    pu_end=$(date +%s%N)
    pu_diff=$(($pu_end-$pu_start))
    pu_time_diff_res=$(echo "scale=10; $pu_diff/$mili" | bc)
    echo -e "\n-----------------------------------------\n" >> "push-group-$member_size-nogc.log"

    gitsize=`du -s --block-size=1 ".git/objects" | awk -F' ' '{print $1}'`
    dcc=`git count-objects -v |
    awk '
    BEGIN { OFS="," }
    {
        gsub(":", "", $1)
        printf "%s,", $2
        sep=","
    }
    END { print "" }
    '`
    echo $start,$time_diff_res,$pu_start,$pu_time_diff_res,$gitsize,$dcc >> "data-group-$member_size-nogc.csv"
done

echo -e "\nDone with size no-gc $member_size\n"
cd ..


echo -e "\nDone with experimetnts\n"