# !/usr/bin/env bash
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd )"

# echo $SCRIPTDIR
# echo $PWD

size4="10240"

CUSTOM_GC=$1

if [[ -z $CUSTOM_GC ]]; then 
    echo "Pass 128, 256, or 512 as first argument"
    exit 1
fi

if [[ $CUSTOM_GC -ne 128 && $CUSTOM_GC -ne 256 && $CUSTOM_GC -ne 512 ]]; then 
    echo "First argument should be either 128, 256, or 512."
    exit 1
fi


# i=512
# if (( $i % $CUSTOM_GC == 0 )); then 
#     echo "mod works"
# fi

# exit 1

REPO_INIT_PATH="/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_1_repo_init/target/release/repo_init"
GROUP_OPS_PATH="/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/_2_group_ops_api/target/release"

GROUP_NAME="hiking"
GROUP_DESC="With my friends family etccc"

member_size=$size4
mili=1000000000


# Insert members of member_size with gc
echo `$REPO_INIT_PATH peer-$member_size-$CUSTOM_GC-gc`
echo `$REPO_INIT_PATH peer-$member_size-$CUSTOM_GC-remote-gc`

cd peer-$member_size-$CUSTOM_GC-gc
git remote add peer-$member_size-$CUSTOM_GC-remote-gc ../peer-$member_size-$CUSTOM_GC-remote-gc
git config gc.auto 1
git config gc.autoPackLimit 1
touch "push-group-$member_size-$CUSTOM_GC-gc.log"
echo "add-mem-time,dif-add-mem-time,push-time,dif-push-time,git-size,count,size,in-pack,packs,size-pack,prune-packable,garbage,size-garbage,None" >  "data-group-$member_size-$CUSTOM_GC-gc.csv"
touch git-gc-out.log
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
echo $gitsize,$dcc 
tstart=$(date +%s%N)
echo $tstart,0,0,0,$gitsize,$dcc >> "data-group-$member_size-$CUSTOM_GC-gc.csv"

for ((i=1; i<=$member_size; i++));do 

    if (( $i % $CUSTOM_GC == 0 )); then 
        git_gc_out=`git gc --aggressive`
        echo -e "$git_gc_out\n" >> git-gc-out.log
    fi
    # Add member
    start=$(date +%s%N)
    $GROUP_OPS_PATH/add_member $GROUP_NAME "peer$i"
    end=$(date +%s%N)
    diff=$(($end-$start))
    time_diff_res=$(echo "scale=10; $diff/$mili" | bc)

    # Push member
    pu_start=$(date +%s%N)
    res=`$SCRIPTDIR/../tests_scripts/push-group-single.sh $GROUP_NAME peer-$member_size-$CUSTOM_GC-remote-gc`
    echo $res | sed 's/\r/\n/g' \
                | grep -E 'done\.|To |remote:' \
                >> "push-group-$member_size-$CUSTOM_GC-gc.log"
    pu_end=$(date +%s%N)
    pu_diff=$(($pu_end-$pu_start))
    pu_time_diff_res=$(echo "scale=10; $pu_diff/$mili" | bc)
    echo -e "\n-----------------------------------------\n" >> "push-group-$member_size-$CUSTOM_GC-gc.log"

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
    echo $start,$time_diff_res,$pu_start,$pu_time_diff_res,$gitsize,$dcc >> "data-group-$member_size-$CUSTOM_GC-gc.csv"
done

echo -e "\nDone with size with gc $member_size with gc every $CUSTOM_GC inserts\n"
cd ..


echo -e "\nDone with experimetnts\n"
