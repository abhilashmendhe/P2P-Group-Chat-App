/*
    To exec: cargo watch -q -c -w src/ -x build
*/

use std::{env::{args, current_dir}, fs::{self, OpenOptions}, io::{self, Write}, path::Path};

use git2::{Oid, Repository};
use sha1::{Digest, Sha1};
use ssh_key::PrivateKey;

fn main() {

    /*
    refname="$1"
    oldrev="$2"
    newrev="$3"
    */

    let args = args().collect::<Vec<String>>();
    // println!("{:?}",args);
    let refname = &args[1];
    let _oldrev = &args[2];
    let newrev = &args[3];

    let _current_path =  current_dir().unwrap();

    let repo = match Repository::open(".") {
        Ok(repo) => repo,
        Err(_) => {
            panic!("Not in git repo. `update` hook!");
        },
    };

    let (_, _, _, _) = pre_checks();

    // println!("'update' hook: Pushed initiated.");
    // println!("Searching for git-ref {}", refname);
    // let found_ref = repo.find_reference(refname).unwrap();
    let dir_newrev = &newrev[..2];
    let file_newrev = &newrev[2..];

    let refname_split = refname.split("/").collect::<Vec<_>>();

    let key_commit_oid = Oid::from_str(&newrev).unwrap();
    
    let commit = repo.find_commit(key_commit_oid).unwrap();
    
    if refname.contains("/pubKey") {
        let commiter_msg = commit.message().unwrap();
        let mut ssh_pub_hasher = Sha1::new();
        ssh_pub_hasher.update(&commiter_msg);
        let sha1_pub_ssh_digest = ssh_pub_hasher.finalize();
        let sha1_pub = format!("{:x}",sha1_pub_ssh_digest);

        if &sha1_pub == &refname_split[3] {
            println!("So far received pub key is valid! Checking if signed!");
            let commit_msg_split = commiter_msg.split(" ").collect::<Vec<_>>();
            let mut data_file = OpenOptions::new()
                                                .append(true)
                                                .open("./.author-cb/allowed_signers")
                                                .unwrap();
            data_file.write(format!("\n{} {} {}", &commit_msg_split[2], &commit_msg_split[0], &commit_msg_split[1]).as_bytes()).unwrap();
            
            if let Ok(_signature) = commit.header_field_bytes("gpgsig") {
                // println!("{:?}", signature.as_str());
                println!("Signed Commit!");
            } else {
                println!("Commit is not signed! Deleting git object!");
                fs::remove_file(format!("./objects/{}/{}",dir_newrev,file_newrev)).unwrap();
            }

        } else {
            println!("Hash don't match!!! Deleting git object!");
            fs::remove_file(format!("./objects/{}/{}",dir_newrev,file_newrev)).unwrap();
        }

    } else if refname.contains("groupConv") {
        // if let Ok(_signature) = commit.header_field_bytes("gpgsig") {
        //     println!("Group ops: Signed Commit!");
        // } else {
        //     println!("Group Ops: Commit is not signed! Deleting git object!");
        //     fs::remove_file(format!("./objects/{}/{}",dir_newrev,file_newrev)).unwrap();
        // }
    }
}

pub fn read_file_to_string<P: AsRef<Path>>(path: P) -> Result<String, io::Error> {
    fs::read_to_string(path)
}

pub fn pre_checks() -> (String, String, String, String) {

    // println!("Started prechecks in update-hook!");
    // println!("Current path: {}", );
    let mut current_path = current_dir()
                                .expect("Failed to get current path in update-hook");
    current_path.push(".author-cb");

    let current_path = current_path.display().to_string();                           
    // println!("Current path: {}", current_path);

    // 1. Check if .author-cb/git-cb and .author-cb/git-cb-email exists
    let peer_name = read_file_to_string(format!("{}/git-cb", current_path))
                        .expect("Can't read the local peer name from git-cb file!");
    let peer_email = read_file_to_string(format!("{}/git-cb-email", current_path))
                        .expect("Can't read the local email from git-cb-email file!");
    
    // 2. Check if keys(priv-pub) in .author-cb/ exists
    let openssh_priv_key = read_file_to_string(format!("{}/key", current_path))
                                    .expect("Peer doesn't have private key");

    let _private_key = PrivateKey::from_openssh(&openssh_priv_key)
                                .expect("Failed to get the private key from openssh");

    let pub_key = read_file_to_string(format!("{}/key.pub", current_path))
                                .expect("Peer doesn't have public key!");
    
    assert_eq!(_private_key.public_key().to_string(), pub_key, "Invalid private-public key pair!");

    // 3. Check if .author-cb/allowed_signers file exists
    let exists_signers = fs::exists(format!("{}/allowed_signers", current_path))
            .expect("Unable to get --- signers");
    assert!(exists_signers);

    // 4. Check if .author-cb/db.csv exists
    let exists_db = fs::exists(format!("{}/db.csv", current_path))
            .expect("Unable to get db.csv file!");
    assert!(exists_db);
    
    (peer_name, peer_email, openssh_priv_key, pub_key)
}