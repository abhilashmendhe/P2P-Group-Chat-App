#!/bin/bash

cd ../push

for ks in `ls`; do 
    
    cd $ks 
    for i in {1..11}; do 
        cd peer$i
        touch peer$i\_extract_push.log
            while IFS= read -r line; do
            # Process each line here
            if [[ "$line" == *"--------------------"* ]]; then 
                break
            fi # elif [[ "$line" == "2025"* ]]; then 
                echo $line
            # fi
            

            # break
            done < peer$i\_PUSH.log
        ls
        cd ..
        break
    done
    echo
    break
    cd ..
done


# 2025-11-28 10:54:01 1764307441246.304164000, from:peer1, to: peer2, tree_id:8826a46b2745991a82a3cd930ab3481ffb68fded, group_name: hiking
# Enumerating objects: 24, done. Counting objects: 4% (1/24)
# Counting objects: 100% (24/24), done. Delta compression using up to 8 threads Compressing objects: 5% (1/18)
# Compressing objects: 100% (18/18), done. Writing objects: 4% (1/24)
# Writing objects: 100% (24/24), 2.40 KiB | 1.20 MiB/s, done. Total 24 (delta 12), reused 0 (delta 0), pack-reused 0 (from 0) remote: Checking connectivity: 24, done. remote: post-receive: oldrev:0000000000000000000000000000000000000000,newrev:130d56f449b34ef27f1836e05d2f31348a141f82,push_recv_time:2025-11-28 10:54:01 1764307441235.880971000, ,push_from:unknown,merge_time:.0365260530,no_mem:3,first:true To ../peer2 peer1_PUSH.log [new reference] groupConv/e0ab8903bd2d/e32e8549b699b584d99a62cc2085d0f5da392c02 -> groupConv/e0ab8903bd2d/e32e8549b699b584d99a62cc2085d0f5da392c02