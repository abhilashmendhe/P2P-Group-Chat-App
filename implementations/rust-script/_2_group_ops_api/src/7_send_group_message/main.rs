use std::{env::args, process::exit};
use _2_group_ops_api::{git_util::create_group_commit, group_utils::get_group_info, peer_in_group::if_peer_member_exists, util::{generate_hash, pre_checks}};
use git2::{Oid, Repository};
use ssh_key::PrivateKey;

/*
    To exec: cargo watch -q -c -w src/7_send_group_message -x build
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
        panic!("Please provide a message to send to the group in \"\"");
    }
    let commit_message = &args[2];

    // 3. Get current index
    let mut curr_index = repo.index()
                            .expect("Not able to fetch the current index of git repo.");

    // 4 Fetch group info
    let group = get_group_info(&repo, &group_name);
    // println!("{:?}",group);
    
    let old_tree_oid = Oid::from_str(&group[4])
                    .expect("Failed to get tree OID from the string OID!");

    let old_tree_struct = repo.find_tree(old_tree_oid)
                    .expect("Failed to retrieve tree struct from the the tree OID!");
    
    let _ = curr_index.read_tree(&old_tree_struct)
            .expect("Failed to get the index tree!");

    let group_id = &group[0];

    // 5. Check if local is admin
    let local_path_str = format!("{}/{}",group_id, local_peer_name);
    if !if_peer_member_exists(&repo, &curr_index, &local_path_str) {
        println!("`{}` does not exists in the group `{}`. Can't send messages.",local_peer_name,group_name); 
        exit(1);
    }

    // 6. Send message to the group
    let pub_key_hash = generate_hash(&pub_key);
    let private_key = PrivateKey::from_openssh(openssh_priv_key)
                    .expect("Failed to get private key from openssh private key!");
    
    let group_reference = format!("refs/heads/groupConv/{}/{}", &group_id[..12], pub_key_hash);

    // 7. Create commit message
    let commit_message = format!("MSG({})", commit_message);
    create_group_commit(
        &repo, 
        old_tree_struct, 
        &group_reference, 
        &local_peer_name, 
        &peer_email, 
        &commit_message, 
        &group_id, 
        Some(private_key)
    );

    println!("{},{} successfully sent message: '{}' to the group '{}'",old_tree_oid.to_string(),local_peer_name,&commit_message,group_name);

}