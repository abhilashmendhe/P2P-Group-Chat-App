use std::{cmp::max, path::Path};

use git2::{Index, Repository};

use crate::git_utils::add_to_current_index;

pub fn merge_group_members(
    repo: &Repository,
    merge_index: &Index, 
    index1: &mut Index, 
    index2: &mut Index, 
    index3: &mut Index
) -> u64 {
    let mut total_members = 0;
    for ind in &mut merge_index.iter() {
        let path_vec = &ind.path;
        if path_vec == "group_name".as_bytes() || path_vec == "group_description".as_bytes() || path_vec == "meta_version".as_bytes() {
            continue;
        }
        let path_str = String::from_utf8_lossy(&path_vec).to_string();
        // println!("{}",path_str);
        let path = Path::new(&path_str);
        let check_index1 = index1.get_path(path, 0);
        let check_index2 = index2.get_path(path, 0);
        
        if check_index1.is_some() && check_index2.is_some() {
            let ind1_oid = check_index1.unwrap().id;
            let ind2_oid = check_index2.unwrap().id;

            let b1 = repo.find_blob(ind1_oid).unwrap();
            let b2 = repo.find_blob(ind2_oid).unwrap();
            
            let b1_str = String::from_utf8_lossy(b1.content());
            let b2_str = String::from_utf8_lossy(b2.content());
            // println!("{:?}",b1.content().split(44));
            let b1_spl = b1_str.split(",").collect::<Vec<&str>>();
            let b2_spl = b2_str.split(",").collect::<Vec<&str>>();

            let b1_mem_int = b1_spl[0].parse::<u32>().unwrap();
            let b1_adm_int = b1_spl[1].parse::<u32>().unwrap();
            let b2_mem_int = b2_spl[0].parse::<u32>().unwrap();
            let b2_adm_int = b2_spl[1].parse::<u32>().unwrap();
            
            let new_mem = max(b1_mem_int, b2_mem_int);
            let new_adm = max(b1_adm_int, b2_adm_int);
            
            let new_blob = format!("{},{}",new_mem,new_adm);
            let _ = add_to_current_index(repo, index3, &path_str, &new_blob);
            // println!("{} is in both index1 and index2.",path_str);
        } else if check_index1.is_some() {
            let _ = index3.add(&check_index1.unwrap());
        } else if check_index2.is_some() {
            let _ = index3.add(&check_index2.unwrap());
        } 
        total_members += 1;
    }
    return total_members;
}

