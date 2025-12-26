use git2::{Commit, Repository, Signature, Tree};
use ssh_key::{HashAlg, PrivateKey};

pub fn create_key_commit(
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