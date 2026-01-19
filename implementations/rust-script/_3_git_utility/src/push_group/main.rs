use std::{env::args, process::Command};

use _3_git_utility::util::{generate_hash, pre_checks};
use git2::Repository;

use crate::group_utils::get_group_info;
mod group_utils;

/*
    Run: cargo watch -q -c -w src/push_group -x build
*/

fn main() {

    // 1. Get remote name as an argument
    let args = args().collect::<Vec<String>>();

    if args.len() < 2 {
        panic!("Please specify the remote peer name to add!");
    }
    let remote_name = &args[1];

    if args.len() < 3 {
        panic!("Please specify the group name!")
    }
    let group_name = &args[2];
    
    // 2. Get current repo
    let repo = match Repository::open(".") {
        Ok(repo) => repo,
        Err(_) => panic!("Not inside a git repo."),
    };

    // 3. Check if remote exists
    let _remote = match repo.find_remote(&remote_name) {
        Ok(remote)  => remote,
        Err(_) => panic!("'{}' remote peer doesn't exists!", &remote_name)
    };

    // 4. Few pre-checks
    let (local_peer_name, 
        _, 
        _, 
        pub_key) = pre_checks();

    let pub_key_hash = generate_hash(&pub_key);
    
    // 5. Get group or groups

    let group = get_group_info(&repo, group_name);
    let g_id = &group[0];
    
    // 6. Push group-ref to remote
    let local_group_ref = format!("refs/heads/groupConv/{}/{}:refs/remotes/groupConv/{}/{}", 
            &g_id[..12], pub_key_hash, &g_id[..12], pub_key_hash);
    
    let output = Command::new("git")
        .args(["push", remote_name, &local_group_ref])
        .output()
        .expect("Failed to execute git push command!");
    
    if output.status.success() {
        println!("Group name: '{}' was pushed from local peer: '{}' to  remote peer: '{}'.",
            group_name,
            local_peer_name, 
            remote_name);    
        let err_output = String::from_utf8_lossy(&output.stderr);
        println!("{}", err_output);
    } else {
        let err_str = String::from_utf8_lossy(&output.stderr);
        println!("{}", err_str);
    }
    
}
