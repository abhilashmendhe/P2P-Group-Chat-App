use std:: path::Path;

use git2::{Index, Repository};

use crate::git_utils::add_to_current_index;

pub fn check_admins(
    repo: &Repository,
    index3: &mut Index
) -> bool {
    
    let mut present = false;
    
    for ind in &mut index3.iter() {
        let path_vec = &ind.path;
        if path_vec == "group_name".as_bytes() || path_vec == "group_description".as_bytes() || path_vec == "meta_version".as_bytes() {
            continue;
        }
        let path_str = String::from_utf8_lossy(&path_vec).to_string();
        // println!("{}",path_str);
        let path = Path::new(&path_str);

        let path_index_entry = index3.get_path(path, 0);

        if path_index_entry.is_some() {

            let oid = path_index_entry.unwrap().id;
            let blob = repo.find_blob(oid).unwrap();

            let b_str = String::from_utf8_lossy(blob.content());
            let b_spl = b_str.split(",").collect::<Vec<_>>();

            let member = b_spl[0].parse::<u32>().unwrap();
            let admin = b_spl[1].parse::<u32>().unwrap();

            if member % 2 == 1 && admin % 2 == 1 {
                present = true;
                break;
            }
        }
    }
    present
}

pub fn make_everyone_admins(
    repo: &Repository,
    index3: &mut Index
) {
    let index_entries = index3.iter().collect::<Vec<_>>();
    // make everyone(current present memebers) admin
    for ind in index_entries {
        let path_vec = &ind.path;
        if path_vec == "group_name".as_bytes() || path_vec == "group_description".as_bytes() || path_vec == "meta_version".as_bytes() {
            continue;
        }
        let path_str = String::from_utf8_lossy(&path_vec).to_string();
        // println!("{}",path_str);
        let path = Path::new(&path_str);

        let path_index_entry = index3.get_path(path, 0);

        if path_index_entry.is_some() {

            let oid = path_index_entry.unwrap().id;
            let blob = repo.find_blob(oid).unwrap();

            let b_str = String::from_utf8_lossy(blob.content());
            let b_spl = b_str.split(",").collect::<Vec<_>>();

            let member = b_spl[0].parse::<u32>().unwrap();
            let mut admin = b_spl[1].parse::<u32>().unwrap();

            if member % 2 == 1 && admin % 2 == 1 {
                admin += 1;
                let new_blob = format!("{},{}",member, admin);
                let _ = add_to_current_index(repo, index3, &path_str, &new_blob);
            }
        }
    }   
}
