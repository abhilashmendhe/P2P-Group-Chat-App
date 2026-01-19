use sha1::{Digest, Sha1};

pub fn generate_hash(value: &str) -> String {
    let mut hash_alg = Sha1::new();
    hash_alg.update(value);
    let sha1_digest = hash_alg.finalize();
    format!("{:x}", sha1_digest)
}