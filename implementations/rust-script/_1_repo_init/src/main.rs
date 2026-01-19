mod error;
mod git_utils;

use std::{env::{args, current_dir}, fs::{self, File, Permissions}, io::Write, os::unix::fs::PermissionsExt};
use git2::Repository;
use regex::Regex;
use sha1::{Digest, Sha1};
use ssh_key::{private::{Ed25519Keypair, KeypairData}, rand_core::OsRng};
use ssh_key::{LineEnding, PrivateKey};
use crate::{error::{Error, Result}, git_utils::create_key_commit};

/*
    To exec: cargo watch -q -c -w src/ -x build
*/
fn main() -> Result<()> {
    
    let mut args = args();
    let repo_name = args.nth(1).expect("Please provide the git repo name or peer name");

    let re = Regex::new(r"^[a-zA-Z]+[a-z0-9._\-]+[a-zA-Z0-9]$")
                .expect("Failed to initialize regex!");

    assert!(re.is_match(&repo_name), 
        "Repo name should start with alphabets followed by any (a-z, A-Z, 0-9, ., -, _) characters, and ends with alphanumeric characters!");

    let email = format!("{}@unibas.ch",repo_name);
    let mut current_path = current_dir()?;
    current_path.push(&repo_name);

    // 0. Get the full path to the currently running executable
    let exe_path = std::env::current_exe().expect("Failed to get current exe path");

    // Get the directory containing the executable
    let mut script_dir = exe_path
        .parent()
        .map(std::path::PathBuf::from)
        .expect("Failed to get parent directory");
    
    script_dir.pop();
    script_dir.pop();
    script_dir.pop();

    // 1. Check if peer/repo already exists; if break
    match Repository::discover(&current_path) {
        Ok(_) => {
            return Err(Error::Git(git2::Error::from_str(format!("Repository already exists: {:?}", &current_path).as_str())));
        },
        Err(_) => {}
    }
    
    // 2. Initialize git repo (peer)
    let repo = Repository::init(&current_path)?;
    println!("Git repo `{repo_name}` initialized in {}",&current_path.to_str().unwrap());

    // 3. Create a folder in 'git_repo_path'/.git/.author-cb (Stores peer info)
    // let mut peer_info_folder = &mut Path::from(current_path);

    fs::create_dir(format!("{}/.git/.author-cb", &current_path.display()))?;

    let mut git_cb = File::create(format!("{}/.git/.author-cb/git-cb", &current_path.display()))?;
    git_cb.write(repo_name.as_bytes())?;
    let mut git_cb_email = File::create(format!("{}/.git/.author-cb/git-cb-email", &current_path.display()))?;
    git_cb_email.write(&email.as_bytes())?;

    // 4. Create a csv file that stores peer's info (for fast lookup)
    std::fs::write(format!("{}/.git/.author-cb/db.csv", &current_path.display()), 
    "id,new_g_name,old_g_name,group_state_tree,created,relay\n")?;

    // 5. Generate SSH(Ed25519) keys. Need keys to sign git commits

    // Generate a new Ed25519 private key
    let ed25519_keypair = KeypairData::Ed25519(Ed25519Keypair::random(&mut OsRng));
    let private_key = PrivateKey::new(ed25519_keypair, &email)?;
    let public_key = private_key.public_key();

    // Write to public and private keys to file
    let priv_pem = private_key.to_openssh(LineEnding::LF)?;
    std::fs::write(format!("{}/.git/.author-cb/key", &current_path.display()), &priv_pem)?;
    std::fs::set_permissions(format!("{}/.git/.author-cb/key", &current_path.display()), Permissions::from_mode(0o600))?;
    
    let pub_ssh = public_key.to_openssh()?;
    std::fs::write(format!("{}/.git/.author-cb/key.pub", &current_path.display()), pub_ssh.to_string())?;
    std::fs::set_permissions(format!("{}/.git/.author-cb/key.pub", &current_path.display()), Permissions::from_mode(0o644))?;
    

    // 6. create .git/.author-cb/allowed_signers file, adding signers information so to authorize git messages
    let mut pub_ssh_split = pub_ssh.split(" ");
    let first = pub_ssh_split.nth(0).unwrap();
    let second = pub_ssh_split.nth(0).unwrap();
    let third = pub_ssh_split.nth(0).unwrap();
    std::fs::write(
    format!("{}/.git/.author-cb/allowed_signers", &current_path.display()), 
    format!("{} {} {}", third, first, second)
    )?;
    
    // 7. Set --local git configs
    let mut config = repo.config()?;
    // config.remove("user.name")?;
    // config.remove("user.email")?;
    config.set_str("user.name", &repo_name)?;
    config.set_str("user.email", &email)?;
    config.set_str("gpg.format", "ssh")?;
    config.set_str("user.signingkey", &pub_ssh)?;
    config.set_str("gpg.ssh.allowedSignersFile", format!("{}/.git/.author-cb/allowed_signers", &current_path.display()).as_str())?;
    config.set_str("commit.gpgsign", "true")?;
    config.set_str("log.showSignature", "true")?;


    // 8. Create a commit message and a reference to the peer's public key
    
    // 8.1 create a referece for your public key
    let mut ssh_pub_hasher = Sha1::new();
    ssh_pub_hasher.update(&pub_ssh);
    let sha1_pub_ssh_digest = ssh_pub_hasher.finalize();
    let pub_key_ref = format!("refs/heads/pubKey/{:x}",sha1_pub_ssh_digest);

    // 8.2 get current index and write empty tree
    let mut current_index = repo.index()?;
    let empty_tree_oid = current_index.write_tree()?;
    let empty_tree = repo.find_tree(empty_tree_oid)?;
    
    create_key_commit(&repo, 
        empty_tree, 
        &pub_key_ref, 
        &repo_name, 
        &email, 
        &pub_ssh, 
        "A reference created public key commit object!", 
        Some(private_key));

    // 9. We need to move the hooks file to .git/hooks folder (yet to write hooks)
    
    // 9.1 Push update hook
    let script_dir_path = script_dir.display();

    fs::copy(
        format!("{}/_4_hooks/target/release/update", script_dir_path), 
        format!("{}/.git/hooks/update", &current_path.display()))
        .expect("Unable to copy `update` hook");
    
    // 9.2 Push post-receive hook
    fs::copy(format!("{}/scripts/post-receive", script_dir_path),
        format!("{}/.git/hooks/post-receive", &current_path.display()))
        .expect("Unable to copy `post-receive` hook");
    
    // 9.3 Also push commit helper
    fs::copy(format!("{}/scripts/commit_helper.sh", script_dir_path),
        format!("{}/.git/hooks/commit_helper.sh", &current_path.display()))
        .expect("Unable to copy `commit_helper.sh` script");

    // 9.4 Also push merge-group-state bin
    fs::copy(format!("{}/_5_merge_group_state/target/release/merge_group_state", script_dir_path),
        format!("{}/.git/hooks/merge_group_state", &current_path.display()))
        .expect("Unable to copy `commit_helper.sh` script");

    Ok(())
}

