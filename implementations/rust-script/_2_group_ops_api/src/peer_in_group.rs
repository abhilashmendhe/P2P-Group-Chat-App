use std::path::Path;

use git2::{Index, Repository};

pub fn if_peer_member_exists(
    repo: &Repository, 
    curr_index: &Index, 
    local_peer_path_str: &str, 
) -> bool {

    let local_path = Path::new(&local_peer_path_str);
    let local_index_entry = curr_index.get_path(local_path, 0);

    if let Some(ie) = local_index_entry {
        let local_blob_oid = ie.id;
        let local_blob_struct = repo.find_blob(local_blob_oid)
                                .expect("Failed to get the local peer blob struct from the group!");
        let local_blob_value = String::from_utf8_lossy(local_blob_struct.content());
        let local_blob_split = local_blob_value.split(",").collect::<Vec<&str>>();

        let local_member_value = local_blob_split[0].parse::<u16>()
                                    .expect("Failed to prase the local member value to u16");
        
        // check if member is present..
        if local_member_value % 2 == 0 {
            false
        } else {
            true
        }
    } else {
        false
    }
}