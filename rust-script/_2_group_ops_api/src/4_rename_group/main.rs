use std::{env::args, path::Path, process::exit};
use _2_group_ops_api::{git_util::{add_to_current_index, create_group_commit}, group_utils::get_group_info, peer_admin::if_peer_admin, util::{generate_hash, modify_db_csv_file, pre_checks}};
use git2::{Oid, Repository};
use ssh_key::PrivateKey;

/*
    To exec: cargo watch -q -c -w src/2_add_member -x build
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
        panic!("Please provide the new group name.");
    }
    let new_group_name = &args[2];

    if args.len() < 4 {
        panic!("Please provide the new group description.");
    }
    let new_group_desc = &args[3];

    // 3. Get current index
    let mut curr_index = repo.index()
                            .expect("Not able to fetch the current index of git repo.");

    // 4. Fetch group info
    let group = get_group_info(&repo, &group_name);
    
    let tree_oid = Oid::from_str(&group[4]);
    let tree_struct = repo.find_tree(tree_oid.unwrap())
                    .expect("Failed to retrieve tree struct from the the tree OID!");
    
    let _ = curr_index.read_tree(&tree_struct)
            .expect("Failed to get the index tree!");

    let group_id = &group[0];

    // 5. Check if local is admin
    let local_path_str = format!("{}/{}",group_id, local_peer_name);
    if !if_peer_admin(&repo, &curr_index, &local_path_str) {
        println!("`{}` does not exists OR is not an admin of the group `{}`. Can't change the description of the group.",local_peer_name,group_name); 
        exit(1);
    }

    // 6. Modify the group name description
    // 6.1 Add new group name to the current index
    add_to_current_index(&repo, &mut curr_index, "group_name", &new_group_name)
        .expect("Failed to add new group name to the current index!");

    // 6.2 Add new group description to the current index
    add_to_current_index(&repo, &mut curr_index, "group_description", &new_group_desc)
        .expect("Failed to add new group description to the current index!");

    // 6.3 Fetch meta version and increment by 1
    let mut meta_version;
    let m_ver_index_entry = curr_index.get_path(Path::new("meta_version"), 0);
    if let Some(ie) = m_ver_index_entry {
        let meta_ver_oid = ie.id;
        let meta_ver_blob = repo.find_blob(meta_ver_oid)
                            .expect("Failed to get the Blob struct!");
        let meta_ver_value = String::from_utf8_lossy(meta_ver_blob.content());
        
        meta_version = meta_ver_value.parse::<u16>()
                            .expect("Failed to parse meta version to u16");
        meta_version += 1;
    } else {
        meta_version = 1;
    }

    let meta_version_str = format!("{}",meta_version);

    // 6.4 Add meta_version to the current index
    add_to_current_index(&repo, &mut curr_index, "meta_version", &meta_version_str)
        .expect("Failed to add the updated meta version to the current index!");

    // 7. Generate new group tree
    let new_group_tree_oid = curr_index.write_tree()
                        .expect("Failed to create new group tree OID!");

    let pub_key_hash = generate_hash(&pub_key);
    let private_key = PrivateKey::from_openssh(openssh_priv_key)
                    .expect("Failed to get private key from openssh private key!");
    let new_group_tree = repo.find_tree(new_group_tree_oid)
                        .expect("Failed to retrieve Tree struct from the new tree OID!");
    
    let group_reference = format!("refs/heads/groupConv/{}/{}", &group_id[..12], pub_key_hash);
    let commit_message = format!("GROUP_OPS({},rename)",format!("'{}' changed to '{}'", group_name, new_group_name));
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

    // 8. Add to db.csv
    modify_db_csv_file(&group_id, &new_group_tree_oid.to_string(), &new_group_name, true);

    println!("{},{}",new_group_tree_oid.to_string(),&commit_message);

}