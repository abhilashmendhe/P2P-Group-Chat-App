use std::io::{self, Write};

use git2::{Oid, Repository};

use crate::util::read_lines_csv;

fn _get_group_info_from_db_csv(repo: &Repository, group_name: &str) -> Vec<Vec<String>> {
    let csv_lines = read_lines_csv(".git/.author-cb/db.csv")
                        .expect("Failed to read db!");
    
    let mut groups = vec![];
    let mut f = true;
    let mut ind = 0;
    for line in csv_lines {
        if f {
            ind += 1;
            f = false;
            continue;
        }
        let content = line.unwrap();
        let content_split = content.split(",").map(|s|s.to_string()).collect::<Vec<_>>();
        let mut group = vec![];

        let tree_id = Oid::from_str(&content_split[3])
                        .expect("Failed to parse to Oid from tree id string!");
        let tree = repo.find_tree(tree_id)
                    .expect("Failed to get the tree object from tree OID!");
        
        // 1. Get group description
        let group_description_obj = match tree.get(1) {
            Some(obj_tree) => obj_tree,
            None => panic!("No group description(blob) found found!"),
        };
        // println!("Group description: {:?}", group_description_obj.name());
        let _g_desc_var = group_description_obj
                        .name()
                        .expect("Unable to get the group description name variable");
        let g_desc_oid = group_description_obj.id();
        let g_desc_blob = repo.find_blob(g_desc_oid)
                            .expect("Failed to get the group description blob!");
        let gr_desc_value = String::from_utf8_lossy(g_desc_blob.content()).to_string();

        // 2. Get meta version
        let meta_version_obj = match tree.get(3) {
            Some(obj_tree) => obj_tree,
            None => panic!("No meta-version(blob) found found!"),
        };
        let _meta_ver_var = meta_version_obj
                        .name()
                        .expect("Unable to get the group meta-version variable");
        let m_ver_oid = meta_version_obj.id();
        let m_ver_blob = repo.find_blob(m_ver_oid)
                            .expect("Failed to get the meta-version blob!");
        let m_ver = String::from_utf8_lossy(m_ver_blob.content()).to_string();
        
        if group_name == content_split[1].clone() {
            group.push(content_split[0].clone());
            group.push(gr_desc_value);
            group.push(content_split[1].clone());
            group.push(m_ver);
            group.push(tree_id.to_string());
            group.push(format!("{}",ind));
            groups.push(group);
        }
        ind += 1;
    }
    
    // println!("{:?}",groups);
    
    groups
}

pub fn get_group_info(repo: &Repository, group_name: &str) -> Vec<String> {
    
    let groups = _get_group_info_from_db_csv(repo, group_name);
    let mut ind = 0;
    if groups.len() > 1 {
        
        for (i, group) in groups.iter().enumerate() {
            let g_id = &group[0];
            let g_desc = &group[1];
            let g_name = &group[2];
            
            println!("{}. {}({}) - {}", i+1, g_name, &g_id[..12], g_desc);
        }
        println!("\nMultiple groups with the name '{}' found.", group_name);
        print!("Enter group number: ");
        io::stdout().flush().unwrap();

        // Wait for user input
        let stdin = io::stdin();
        let mut input = String::new();
        stdin.read_line(&mut input).unwrap();
        
        let trim_input = input.trim();
        let number = trim_input.parse::<usize>()
                    .expect("Number should be greater than 0");

        ind = number - 1;
    } else if groups.len() == 0 {
        panic!("No group '{}' found!", group_name);
    }
    
    groups[ind].clone()
}

pub fn _get_group_info_from_reference(repo: &Repository, group_name: &str) -> Vec<Vec<String>> {

    let references = repo.references()
                    .expect("Failed to get the references!");
    
    let mut groups = vec![];

    for refs in references {
        let refs = refs.expect("Failed to get reference!");
        let mut group = Vec::new();
        if let Some(ref_name) = refs.name() {
            if ref_name.contains("refs/heads/groupConv") {
                let commit = refs.peel_to_commit()
                    .expect("Failed to peel to commit from reference!");
                let tree = commit.tree()
                            .expect("Failed to retrieve associated tree from the commit!");
                
                // 1. Sub-tree group-id
                let group_id_obj = match tree.get(0) {
                    Some(obj_tree) => obj_tree,
                    None => panic!("No group-id(sub-tree) found!"),
                };
                let group_id = group_id_obj.name().unwrap().to_string();
                // println!("Group id: {:?}", group_id_obj.name());

                // 2. Group description
                let group_description_obj = match tree.get(1) {
                    Some(obj_tree) => obj_tree,
                    None => panic!("No group description(blob) found found!"),
                };
                // println!("Group description: {:?}", group_description_obj.name());
                let _g_desc_var = group_description_obj
                                .name()
                                .expect("Unable to get the group description name variable");
                let g_desc_oid = group_description_obj.id();
                let g_desc_blob = repo.find_blob(g_desc_oid)
                                    .expect("Failed to get the group description blob!");
                let gr_desc_value = String::from_utf8_lossy(g_desc_blob.content()).to_string();
                // println!("{}: {}", g_desc_var, gr_desc_value);

                // 3. Group name
                let group_name_obj = match tree.get(2) {
                    Some(obj_tree) => obj_tree,
                    None => panic!("No group name(blob) found found!"),
                };
                // println!("Group name: {:?}", group_name_obj.name());
                let _g_name_var = group_name_obj
                                .name()
                                .expect("Unable to get the group name name variable");
                let g_name_oid = group_name_obj.id();
                let g_name_blob = repo.find_blob(g_name_oid)
                                    .expect("Failed to get the group name blob!");
                let gr_name_value = String::from_utf8_lossy(g_name_blob.content()).to_string();
                // println!("{}: {}", g_name_var, gr_name_value);

                // 4. Meta-version
                let meta_version_obj = match tree.get(3) {
                    Some(obj_tree) => obj_tree,
                    None => panic!("No meta-version(blob) found found!"),
                };
                let _meta_ver_var = meta_version_obj
                                .name()
                                .expect("Unable to get the group meta-version variable");
                let m_ver_oid = meta_version_obj.id();
                let m_ver_blob = repo.find_blob(m_ver_oid)
                                    .expect("Failed to get the meta-version blob!");
                let m_ver = String::from_utf8_lossy(m_ver_blob.content()).to_string();
                // println!("{}: {}", meta_ver_var, m_ver);
                // println!();
                if gr_name_value == group_name {
                    group.push(group_id);
                    group.push(gr_desc_value);
                    group.push(gr_name_value);
                    group.push(m_ver);
                    groups.push(group);
                }
            }
        }
    }
    groups
}
