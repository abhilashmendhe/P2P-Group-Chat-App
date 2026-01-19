use std::{env::args, process::Command};

use _3_git_utility::util::{generate_hash, pre_checks};
// use git2::{PushOptions, RemoteRedirect, Repository};
use git2::Repository;
/*
    Run: cargo watch -q -c -w src/push_key -x build
*/
fn main() {

    // 1. Get remote name as an argument
    let args = args().collect::<Vec<String>>();

    if args.len() < 2 {
        panic!("Please specify the remote peer name!");
    }
    let remote_name = &args[1];

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

    // 5. Push keyref to remote
    let local_peer_key_ref = format!("refs/heads/pubKey/{}:refs/remotes/pubKey/{}", pub_key_hash,pub_key_hash);
    
    // Only push works when it is git bare repo
    // let mut push_opts = PushOptions::new();
    // push_opts.follow_redirects(RemoteRedirect::All); // Follow all redirects

    // let mut remote = _remote;
    // remote.push(&[local_peer_key_ref], Some(&mut push_opts))
        // .expect("Failed to push pub key!");
    
    println!("Pushed ref: {} to {}\n", local_peer_key_ref, remote_name);
    let output = Command::new("git")
        .args(["push", remote_name, &local_peer_key_ref])
        .output()
        .expect("Failed to execute git push command!");

    if output.status.success() {
        println!("'{}' pub-key was pushed to '{}' remote peer.", local_peer_name, remote_name);
        let err_output = String::from_utf8_lossy(&output.stderr);
        println!("{}", err_output);
    } else {
        let err_str = String::from_utf8_lossy(&output.stderr);
        println!("{}", err_str);
    }
}