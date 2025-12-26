use std::path::Path;

use git2::{Index, MergeOptions, Oid, Repository};

use crate::{git_utils::add_to_current_index, merge::{check_admins::{check_admins, make_everyone_admins}, merge_group_desc::merge_group_description, merge_group_members::merge_group_members}};

pub fn merge_tree(repo: &Repository, tree1: &str, tree2: &str) -> (Oid,u64) {
    // println!("In merge_tree func");
    // println!("tree1:{}",tree1);
    // println!("tree2:{}",tree2);
    let t1_oid = Oid::from_str(&tree1);
    let t1_struct = repo.find_tree(t1_oid.unwrap()).unwrap();

    let t2_oid = Oid::from_str(&tree2);
    let t2_struct = repo.find_tree(t2_oid.unwrap()).unwrap();

    let mut index1 = Index::open(Path::new("./.git/index")).unwrap();
    let _ = index1.read_tree(&t1_struct);

    let mut index2 = Index::open(Path::new("./.git/index")).unwrap();
    let _ = index2.read_tree(&t2_struct);

    let mopt = MergeOptions::new();

    let empty_oid = Oid::from_str("4b825dc642cb6eb9a060e54bf8d69288fbee4904");
    let t3_struct = repo.find_tree(empty_oid.unwrap()).unwrap();
    let merge_index = repo.merge_trees(&t3_struct, &t1_struct, &t2_struct,Some(&mopt)).unwrap();
    
    let mut index3 = Index::open(Path::new("./.git/index")).unwrap();
    let _ = repo.set_index(&mut index3);

    // 1. Merge group description and add it to the git index
    let (name3, desc3, meta3) = merge_group_description(&repo, &mut index1, &mut index2);
    let _ = add_to_current_index(&repo, &mut index3, "group_name", &name3);
    let _ = add_to_current_index(&repo, &mut index3, "group_description", &desc3);
    let _ = add_to_current_index(&repo, &mut index3, "meta_version", &meta3);

    // 2.Merge group members
    let total_members = merge_group_members(&repo, &merge_index, &mut index1, &mut index2, &mut index3);
    
    // 3. Check admins presence
    let flag = check_admins(&repo, &mut index3);

    if !flag {
        make_everyone_admins(&repo, &mut index3);
    }

    let new_t_oid = index3.write_tree().unwrap();
    (new_t_oid, total_members)
}

