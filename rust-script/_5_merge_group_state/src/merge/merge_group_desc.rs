use std::path::Path;

use git2::{Index, Repository};

use crate::utils::generate_hash;

pub fn merge_group_description(repo: &Repository, index1: &mut Index, index2: &mut Index) -> (String, String, String) {
    let name = Path::new("group_name");
    let desc = Path::new("group_description");
    let meta = Path::new("meta_version");

    let meta_ver1 = index1.get_path(meta, 0).unwrap();
    let name_ie1 = index1.get_path(name, 0).unwrap();
    let desc_ie1 = index1.get_path(desc, 0).unwrap();

    let meta_ver2 = index2.get_path(meta, 0).unwrap();
    let name_ie2 = index2.get_path(name, 0).unwrap();
    let desc_ie2 = index2.get_path(desc, 0).unwrap();
    
    let meta_oid1 = meta_ver1.id;
    let name_oid1 = name_ie1.id;
    let desc_oid1 = desc_ie1.id;

    let meta_oid2 = meta_ver2.id;
    let name_oid2 = name_ie2.id;
    let desc_oid2 = desc_ie2.id;

    let meta_int1 = String::from_utf8_lossy(&repo.find_blob(meta_oid1).unwrap().content()).parse::<i32>().unwrap();
    let find_name1 = &repo.find_blob(name_oid1).unwrap();
    let name1 = String::from_utf8_lossy(&find_name1.content());
    let find_desc1 = &repo.find_blob(desc_oid1).unwrap();
    let desc1 = String::from_utf8_lossy(&find_desc1.content());

    let meta_int2 = String::from_utf8_lossy(&repo.find_blob(meta_oid2).unwrap().content()).parse::<i32>().unwrap();
    let find_name2 = &repo.find_blob(name_oid2).unwrap();
    let name2 = String::from_utf8_lossy(&find_name2.content());
    let find_desc2 = &repo.find_blob(desc_oid2).unwrap();
    let desc2 = String::from_utf8_lossy(&find_desc2.content());

    if meta_int1 > meta_int2 {
        return (name1.to_string(), desc1.to_string(), meta_int1.to_string());
    } else if meta_int2 > meta_int1 {
        return (name2.to_string(), desc2.to_string(), meta_int2.to_string());
    } else {
        let name_desc1 = format!("{}{}",name1, desc1);
        let name_desc_sha1 = generate_hash(&name_desc1);

        let name_desc2 = format!("{}{}",name2, desc2);
        let name_desc_sha2 = generate_hash(&name_desc2);

        if name_desc_sha1 > name_desc_sha2 {
            return (name1.to_string(), desc1.to_string(), meta_int1.to_string());
        } else if name_desc_sha2 > name_desc_sha1 {
            return (name2.to_string(), desc2.to_string(), meta_int2.to_string());
        }

    }
    (name2.to_string(), desc2.to_string(), meta_int2.to_string())
}