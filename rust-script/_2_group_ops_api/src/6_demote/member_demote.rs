use std::{path::Path, process::exit};

use git2::{Index, Repository};

pub fn demote_member_func(
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

        let remote_member_value = remote_blob_split[0].parse::<u16>()
                                    .expect("Failed to parse the remote member value to u16");
        
        let mut remote_admin_value = remote_blob_split[1].parse::<u16>()
            .expect("Failed to parse the remote admin value to u16");

        // First check if the member is present inside the group. If present then promote.
        if remote_member_value % 2 == 0 {
            println!("{} is currently not present inside the group!. Can't demote!", remote_name);
            exit(1);
        }

        // Now check if member is already an admin or not
        if remote_admin_value % 2 == 0 {
            println!("{} is not an admin of the group '{}'. Can't demote!", remote_name, group_name);
            exit(1);
        } else {
            remote_admin_value += 1;
        }

        format!("{},{}", remote_member_value, remote_admin_value)

    } else {
        println!("{} doesn't exists in the group '{}'", remote_name, group_name);
        exit(1);
    }
}