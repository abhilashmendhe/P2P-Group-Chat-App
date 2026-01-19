/*
    To exec: cargo watch -q -c -w src/ -x build
*/

use std::{env::current_dir, io, path::Path};

use _4_hooks::util::pre_checks;
use git2::{Oid, Repository};

fn main (){

    let mut git_input = "".to_string();

    io::stdin()
        .read_line(&mut git_input)
        .expect("Failed to read line");

    let params = git_input
                        .trim()
                        .split_whitespace()
                        .collect::<Vec<_>>();
    let oldrev = params[0];
    let newrev = params[1];
    let refname = params[2];

    if refname.contains("groupConv") {
        let group_refname_spl = refname.split("/").collect::<Vec<_>>();
        let sub_group_id = group_refname_spl[3];

        let _current_path =  current_dir().unwrap();

        let repo = match Repository::open(".") {
            Ok(repo) => repo,
            Err(_) => {
                panic!("Not in git repo. `update` hook!");
            },
        };

        let (local_peer_name, _, _, _) = pre_checks();

        println!("`post-receive` hook: Pushed initiated!");


        let mut curr_index = repo.index()
                        .expect("Failed to get the Index!");
        
        let commit_oid = Oid::from_str(&newrev)
                    .expect("Failed to convert str to Oid!");
        let commit= repo.find_commit(commit_oid)
                    .expect("Not commit found!");

        let tree = commit.tree()
                    .expect("Failed to get tree from the commit object!");
        
        curr_index.read_tree(&tree).expect("Failed to get the index from the tree object!");

        let mut group_id = String::new();
        for tree_entry in tree.iter() {
            if let Some(path_name) = tree_entry.name() {
                if path_name.starts_with(sub_group_id) {
                    group_id.push_str(path_name);
                    break;
                }
            }
        }
        // println!("Group id: {}",group_id);

        let group_local_path_str = format!("{}/{}", group_id, local_peer_name);
        // println!("{:?}",tree);
        let local_path = Path::new(&group_local_path_str);
        let local_index_entry = curr_index.get_path(local_path, 0);
        if let Some(ie) = local_index_entry {
            println!("{} present in the group",local_peer_name);
        }
    }
}