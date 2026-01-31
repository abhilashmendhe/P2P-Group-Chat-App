use std::{path::Path, process::exit};

use git2::{Index, Repository};

pub fn add_member_func(
    repo: &Repository, 
    curr_index: &mut Index, 
    remote_path_str: &str, 
    group_name: &str, 
    remote_name: &str) -> String {

    let remote_path = Path::new(&remote_path_str);
    let remote_index_entry = curr_index.get_path(remote_path, 0);

    if let Some(ie) = remote_index_entry {
        let remote_blob_oid = ie.id;
        let remote_blob_struct = repo.find_blob(remote_blob_oid)
                                .expect("Failed to get the remote peer blob struct from the group!");
        let remote_blob_value = String::from_utf8_lossy(remote_blob_struct.content());
        let remote_blob_split = remote_blob_value.split(",").collect::<Vec<&str>>();

        let mut remote_member_value = remote_blob_split[0].parse::<u16>()
                                    .expect("Failed to parse the remote member value to u16");
        if remote_member_value % 2 == 1 {
            println!("{} already exists in the group '{}'", remote_name, group_name);
            exit(1);
        } else {
            remote_member_value += 1;
        }

        let mut remote_admin_value = remote_blob_split[1].parse::<u16>()
                                    .expect("Failed to parse the remote member value to u16");
        if remote_admin_value % 2 == 1 {
            remote_admin_value += 1;
        }

        format!("{},{}", remote_member_value, remote_admin_value)
    } else {
        String::from("1,0")
    }
}