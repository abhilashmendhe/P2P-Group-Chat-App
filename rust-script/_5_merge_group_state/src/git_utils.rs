use git2::{Error, Index, IndexEntry, IndexTime, Oid, Repository};

pub fn generate_index_entry(path: Vec<u8>, git_oid: Oid, flag_size: u16) -> IndexEntry {
    IndexEntry { 
        ctime: IndexTime::new(0, 0), 
        mtime: IndexTime::new(0, 0), 
        dev: 0, 
        ino: 0, 
        mode: 33188, 
        uid: 0, 
        gid: 0, 
        file_size: 0, 
        id: git_oid, 
        flags: flag_size, 
        flags_extended: 0, 
        path
    }
}

pub fn add_to_current_index(repo: &Repository, curr_index: &mut Index, path: &str, value: &str) -> Result<(), Error> {
    
    let blob_oid = repo.blob(value.as_bytes())
                        .expect("Not able to create blob");
    let path_bytes = path.as_bytes().to_vec();
    let path_bytes_len = path_bytes.len() as u16;
    let path_index_entry = generate_index_entry(
                                    path_bytes, 
                            blob_oid, 
                            path_bytes_len);
    curr_index.add_frombuffer(&path_index_entry, value.as_bytes())
}