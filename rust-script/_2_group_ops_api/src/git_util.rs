use git2::{Commit, Error, Index, IndexEntry, IndexTime, Oid, Repository, Signature, Tree};
use ssh_key::{HashAlg, PrivateKey};

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

pub fn create_group_commit(
    repo: &Repository, 
    git_tree: Tree, 
    git_ref: &str, 
    name: &str, 
    email: &str,
    commit_message: &str,
    gid: &str,
    private_key: Option<PrivateKey>) {
    
    // 0. First we get all the parents of the previous commits
    let mut git_refs = repo.references()
                                        .expect("Failed to retrieve all the git references!");

    let git_ref_names = git_refs.names();

    let sub_gid = &gid[0..12];
    let mut parents = Vec::new();
    for reff in git_ref_names {
        let ref_name = reff.unwrap();
        if ref_name.contains(sub_gid) {
            let ref_commit = repo
                                    .find_reference(ref_name)
                                    .expect("Failed to find the reference!")
                                    .peel_to_commit()
                                    .expect("Failed to peel the git commit!");
            parents.push(ref_commit);
        }
    }

    // turn parents to references commits elements inside vec
    let collected_parents = parents.iter().take(parents.len()).collect::<Vec<_>>();
    
    // 1. Create a signature
    let signature = Signature::now(name, email)
                                        .expect("Failed to create git signature!");

    create_commit(
        repo, 
        git_tree, 
        git_ref, 
        commit_message, 
        commit_message, 
        signature, 
        collected_parents, 
        private_key);
}

pub fn _create_key_commit(
    repo: &Repository, 
    git_tree: Tree, 
    git_ref: &str, 
    name: &str, 
    email: &str,
    commit_message: &str,
    ref_message: &str,
    private_key: Option<PrivateKey>) {

    // 1. Create a signature
    let signature: Signature<'static> = Signature::now(name, email)
                                        .expect("Failed to create git signature!");   
    create_commit(
        repo, 
        git_tree, 
        git_ref, 
        commit_message,
        ref_message,
        signature, 
        (&[]).to_vec(), 
        private_key);
}

fn create_commit(
    repo: &Repository, 
    git_tree: Tree, 
    git_ref: &str, 
    commit_message: &str,
    ref_message: &str,
    signature: Signature<'static>,
    parents: Vec<&Commit<'_>>,
    private_key: Option<PrivateKey>) {
            
    match private_key {
        Some(private_key) => {
            
            // 2. Create a commit buffer to pass to the commit signed method
            let commit_buffer = repo.commit_create_buffer(
                &signature, 
                &signature, 
                &commit_message, 
                &git_tree,
                &parents
            ).expect("Failed to create commit buffer!");

            // 3. Convert commit buffer to string
            let commit_buffer_str = str::from_utf8(&commit_buffer)
                                        .expect("Unable to conver to commit buffer &str from utf8");

            // 4. Now sign the content of commit_buffer_str
            let key_signed = private_key.sign(
                        "git", 
                        HashAlg::default(), 
                        commit_buffer_str.as_bytes())
                        .expect("Failed to sign the commit buffer!");
    
            // 5. Generate signed commit
            let signed_commit_oid = repo.commit_signed(
                commit_buffer_str, 
                key_signed.to_string().as_str(), 
                None
            ).expect("Failed to create git signed commit!");

            let _git_ref = repo.reference(
                git_ref, 
                signed_commit_oid, 
                true, 
                &commit_message
            );
        },
        None => {
            repo.commit(Some(git_ref), 
            &signature, 
        &signature, 
                    &ref_message, 
                    &git_tree, 
                    &parents
            ).expect("Failed to create commit!");
        }
    }

}