
/*
    To exec: cargo watch -q -c -w src/1_create_group -x build
*/

use std::{env::args, fs::OpenOptions, io::Write, time::{SystemTime, UNIX_EPOCH}};

use _2_group_ops_api::{git_util::{add_to_current_index, create_group_commit}, util::{generate_hash, pre_checks, read_file_to_string}};
use git2::Repository;
use ssh_key::PrivateKey;

// use crate::{git_util::{add_to_current_index, create_group_commit}, util::{generate_hash, pre_checks, read_file_to_string}};


fn main() {

    // 1. Check if you are inside the current git repo
    let repo = match Repository::open(".") {
        Ok(repo) => repo,
        Err(_) => panic!("Not in a valid git repo!"),
    };

    // 1.2 Do more pre-checks and fetch peer-name and peer-email

    let (peer_name, peer_email,openssh_priv_key, _) = pre_checks();
    
    let mut curr_index = repo.index()
                            .expect("Not able to fetch the current index of git repo.");

    // 2. Get 2 arguments, group name & group description
    let args = args().collect::<Vec<String>>();

    if args.len() < 2 {
        panic!("Please specify the group name");
    }
    let group_name = &args[1];

    if args.len() < 3 {
        panic!("Please provide the group description inside \"\" less than 100 characters");
    }
    let group_description = &args[2];
    
    // 3. Now get the current epoch time and concat it with group name
    let epoch = SystemTime::now()
                                            .duration_since(UNIX_EPOCH)
                                            .expect("SystemTime before UNIX EPOCH!");
    
    let group_name_epoch = format!("{}{:?}", group_name, epoch);

    // 4. Apply SHA1 over the concat string of group name and epoch to create unique group ID
    let group_id = generate_hash(&group_name_epoch);

    // 5. Now create group using git objects

    // Get current peer name and email
    
    // 5.1.1 Add group name to current index
    add_to_current_index(&repo, &mut curr_index, "group_name", &group_name)
            .expect("Not able to add group name to current index");
    // 5.1.2 Add group description to current index
    add_to_current_index(&repo, &mut curr_index, "group_description", &group_description)
            .expect("Not able to add group description to current index");
    // 5.1.3 Add meta_version to current index
    add_to_current_index(&repo, &mut curr_index, "meta_version", "1")
            .expect("Unable to add meta version to current group index");
    // 5.1.4 Add peer group value which is 1,1
    add_to_current_index(&repo, &mut curr_index, &format!("{}/{}",group_id,peer_name), "1,1")
            .expect("Unable to add group_id/peer to current group index");

    // 5.2 create a new group tree
    let new_group_tree = curr_index.write_tree()
                            .expect("Unable to create new git tree object from current index.");
    
    // 5.3.1 Read private key from file
    let private_key = PrivateKey::from_openssh(openssh_priv_key)
                                    .expect("Failed to create private key from openssh!");
    
    // 5.3.2 Read public key and convert to hash
    let pub_key_string = read_file_to_string(".git/.author-cb/key.pub")
                                    .expect("Failed to read public key.");
    let pub_key_hash = generate_hash(&pub_key_string);

    // 5.4 Get Tree object
    let g_tree = repo.find_tree(new_group_tree)
                                .expect("Failed to get the git Tree struct");
    
    // 5.5 Create a commit message
    let commit_msg = format!("GROUP_OPS('{}' group created by {},create)",group_name, peer_name);

    // 5.6 Create a reference
    // 5.6.1 First 12 characters of group id
    let sub_group_id = &group_id[0..12];
    let git_ref = format!("refs/heads/groupConv/{}/{}", sub_group_id, pub_key_hash);

    // 5.3 Create a new commit
    create_group_commit(
        &repo, 
g_tree, 
        &git_ref, 
        &peer_name, 
        &peer_email, 
        &commit_msg, 
        &group_id, 
Some(private_key));

        // 6. Write to db.csv
        let mut db_file = OpenOptions::new()
                                .append(true)
                                .open(".git/.author-cb/db.csv")
                                .expect("Unable to open db.csv file!");
        let db_content = format!("{},{},{},{},{},{}\n",&group_id,&group_name,"",new_group_tree.to_string(),"local","no");
        db_file.write(db_content.as_bytes()).expect("Failed to append to db.csv!");
        println!("{}", &commit_msg);
}
