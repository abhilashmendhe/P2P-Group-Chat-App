use std::{env, process::exit};

use _5_merge_group_state::merge::merge_tree_state::merge_tree;
use git2::Repository;

fn main() {

    // 1. Get tree objects from arguments
    let tree1 = env::args().nth(1).unwrap();
    let tree2 = env::args().nth(2).unwrap();

    // 2. Optional: Check if in valid git repo
    // Open repository
    let repo = match Repository::open(".") {
        Ok(repo) => repo,
        Err(_) => {
            println!("Error opening git repository. Please check if you are inside a git repository");
            exit(1);
        }
    };
    
    // 3. Call merge group state function
    let (oid, total_members) = merge_tree(&repo, &tree1, &tree2);
    print!("{:?},{}",oid,total_members);
}
