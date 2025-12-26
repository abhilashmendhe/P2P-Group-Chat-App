use std::{env::current_dir, fs::{self, File}, io::{self, BufRead}, path::Path};

use sha1::{Digest, Sha1};
use ssh_key::PrivateKey;

pub fn generate_hash(value: &str) -> String {
    let mut hash_alg = Sha1::new();
    hash_alg.update(value);
    let sha1_digest = hash_alg.finalize();
    format!("{:x}", sha1_digest)
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

pub fn read_lines_csv<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}

pub fn modify_db_csv_file(gid: &str, new_tree: &str) {
    let mut all_lines = String::new();
    
    let gid_len = gid.len()-1;

    let n_gid = &gid[0..gid_len];
    
    if let Ok(lines) = read_lines_csv("./.git/.author-cb/db.csv") {
        // Consumes the iterator, returns an (Optional) String
        for line in lines.flatten() {
            
            if line.contains(n_gid) {
                let line_spl = line.split(",").collect::<Vec<&str>>();
                // println!("{:?}",line_spl);
                let new_st = format!("{},{},,{},{}",line_spl[0],line_spl[1],new_tree,line_spl[4]);
                // println!("{}",new_st);
                all_lines.push_str(&new_st);
                all_lines.push('\n');
            } else {
                all_lines.push_str(&line);
                all_lines.push('\n');
            }
        }
        
    } else {
        panic!("Error reading db.csv");
    }
    fs::write("./.git/.author-cb/db.csv",all_lines).unwrap();
    
    // let _ = fp.flush();
}