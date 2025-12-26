use std::env::args;

use _3_git_utility::util::pre_checks;
use git2::Repository;

/*
    Run: cargo watch -q -c -w src/add_remote -x build
*/

fn main() {

    // 1. Get 2 arguments, remote name and remote path(url)
    let args = args().collect::<Vec<String>>();

    if args.len() < 2 {
        panic!("Please specify the remote peer name to add!");
    }
    let remote_name = &args[1];

    if args.len() < 3 {
        panic!("Please provide the remote peer path");
    }

    let remote_path = &args[2];

    // 2. Get current repo
    let repo = match Repository::open(".") {
        Ok(repo) => repo,
        Err(_) => panic!("Not inside a git repo."),
    };

    // 3. Few pre-checks
    pre_checks();

    // 4. Now add remote
    repo.remote(&remote_name, &remote_path)
        .expect("Failed to add remote peer!");

    println!("'{}' remote peer added!", remote_name);
}