use std::{env::args, process::exit};
use _2_group_ops_api::{git_util::{add_to_current_index, create_group_commit}, group_utils::get_group_info, peer_admin::if_peer_admin, util::{generate_hash, modify_db_csv_file, pre_checks}};
use git2::{Oid, Repository};
use ssh_key::PrivateKey;

use crate::member_remove::remove_member_func;

mod member_remove;
/*
    To exec: cargo watch -q -c -w src/3_remove_member -x build
*/

fn main() {
    
    // 1. Check if you are inside the current git repo
    let repo = match Repository::open(".") {
        Ok(repo) => repo,
        Err(_) => panic!("Not in a valid git repo!"),
    };

    // 1.2 Do more pre-checks and fetch peer-name and peer-email

    let (local_peer_name, peer_email, openssh_priv_key, pub_key) = pre_checks();
    
    // 2. Get 2 arguments, group name & group description
    let args = args().collect::<Vec<String>>();

    if args.len() < 2 {
        panic!("Please specify the group name.");
    }
    let group_name = &args[1];

    if args.len() < 3 {
        panic!("Please provide the remote peer name to remove from the group.");
    }
    let remote_name = &args[2];

    // 3 Get current index
    let mut curr_index = repo.index()
                            .expect("Not able to fetch the current index of git repo.");

    // 4 Fetch group info
    let group = get_group_info(&repo, &group_name);
    // println!("{:?}",group);
    
    let tree_oid = Oid::from_str(&group[4]);
    let tree_struct = repo.find_tree(tree_oid.unwrap())
                    .expect("Failed to retrieve tree struct from the the tree OID!");
    
    let _ = curr_index.read_tree(&tree_struct)
            .expect("Failed to get the index tree!");

    let group_id = &group[0];

    // 5. Check if local is admin
    let local_path_str = format!("{}/{}",group_id, local_peer_name);
    if !if_peer_admin(&repo, &curr_index, &local_path_str) {
        println!("`{}` does not exists OR is not an admin of the group `{}`. Can't perform 'remove' operation.",local_peer_name,group_name); 
        exit(1);
    }
    
    // 6. Check if remote peer already exists in the group
    let remote_path_str = format!("{}/{}", group_id, remote_name);
    let tup_value = remove_member_func(&repo, &mut curr_index, &remote_path_str, group_name, remote_name);

    // 7. Add to the current index
    add_to_current_index(&repo, &mut curr_index, &remote_path_str, &tup_value)
    .expect("Failed to modify(remove) the existing member to the current index!");

    // 8. Generate new group tree
    let new_group_tree_oid = curr_index.write_tree()
                        .expect("Failed to create new group tree OID!");

    // println!("{:?}",new_group_tree_oid);

    let pub_key_hash = generate_hash(&pub_key);
    let private_key = PrivateKey::from_openssh(openssh_priv_key)
                    .expect("Failed to get private key from openssh private key!");
    let new_group_tree = repo.find_tree(new_group_tree_oid)
                        .expect("Failed to retrieve Tree struct from the new tree OID!");
    
    let group_reference = format!("refs/heads/groupConv/{}/{}", &group_id[..12], pub_key_hash);
    
    // 9. Create new commit message
    let commit_message = format!("GROUP_OPS({},remove)",format!("{} removed from the group {}", remote_name, group_name));
    create_group_commit(
        &repo, 
        new_group_tree, 
        &group_reference, 
        &local_peer_name, 
        &peer_email, 
        &commit_message, 
        &group_id, 
        Some(private_key)
    );

    // 10. Add to db.csv
    // modify_db_csv_file(&group_id, &new_group_tree_oid.to_string());
    modify_db_csv_file(&group_id, &new_group_tree_oid.to_string(), &group_name, false);
    println!("{},{}",new_group_tree_oid.to_string(),&commit_message);

}