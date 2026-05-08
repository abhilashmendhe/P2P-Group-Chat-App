import os 
import sys 
import subprocess
from pygit2 import Repository, Tree
# p_time_from,from,to,treeId,objsize,total_objs,delta_objs,old_c,new_c,p_time_to,merge_time,member_size,reftype

def extract_content(ppath: str, repo: Repository, logfile: str) -> str:
    # print(logfile)
    count = 0
    fulls = "p_time_from,from,to,treeId,objsize,total_objs,delta_objs,old_c,new_c,p_time_to,merge_time,member_size,reftype\n"
    
    time=""
    puf = ""
    put = ""
    total_objs = 0
    delta_objs = 0
    tree_id = "0000000000000000000000000000000000000000"
    old_c = "0000000000000000000000000000000000000000"
    new_c = "0000000000000000000000000000000000000000"
    t_objsize = 0
    merge_time = 0.0
    m_count = 0
    reftype = ""
    try:
        with open(logfile, "+r") as file:
            for line in file:
                line = line.strip()
                if line.startswith("2025"):
                    infos = line.split(",")
                    time = infos[0]
                    puf = infos[1][6:].strip()
                    put = infos[2][4:].strip()
                    reftype = "head"
                    fulls += f"{time},{put},{puf},{tree_id},{t_objsize},{total_objs},{delta_objs},{old_c},{new_c},{time},{merge_time},{m_count},{reftype}\n"
                    # print(f"{time},{put},{puf},{tree_id},{t_objsize},{total_objs},{delta_objs},{old_c},{new_c},{time},{merge_time},{m_count},{reftype}")

                elif line.startswith("remote:"):
                    tind = line.index("Total") + 5
                    bind = line.index("(")
                    dind = line.index(")")
                    total_objs = line[tind:bind].strip()
                    delta_objs = line[bind+6:dind].strip()
                    
                elif line.startswith("Unpack"):
                    
                    first_comma = line.find(",")
                    first_or = line.find("|")
                    if first_comma == -1:
                        continue
                    # print(first_comma, first_or)
                    obj_size = line[first_comma+1:first_or].strip().split()
                    # print("here")
                    
                    if obj_size[1][0] == 'K':
                        t_objsize += (float(obj_size[0]) * 1000)
                    elif obj_size[1][0] == 'M':
                        t_objsize += (float(obj_size[0]) * 1000000)
                    elif obj_size[1][0] == 'G':
                        t_objsize += (float(obj_size[0]) * 1000000000)
                    else:
                        t_objsize += float(obj_size[0])

                    orc_ind = line.find("old_r_c")
                    if orc_ind > -1:
                        data = line[orc_ind:].split(",")
                        old_c = data[0][8:]
                        new_c = data[1][8:].split()[0]
                        merge_time = data[-2][10:]
                        tree_id = data[-3][9:]
                        # print("uncap")
                        # tree_obj = repo.get(new_c).tree
                        # print("Unpack",tree_obj, tree_id)
                        commit_obj = repo.get(new_c)
                        if not commit_obj:
                            total_objs = 0
                            delta_objs = 0
                            tree_id = "0000000000000000000000000000000000000000"
                            old_c = "0000000000000000000000000000000000000000"
                            new_c = "0000000000000000000000000000000000000000"
                            t_objsize = 0
                            merge_time = 0.0
                            m_count = 0
                            continue
                        tree_obj = commit_obj.tree
                        tree_id = tree_obj.id
                        tree_id = tree_obj.id
                        m_count = 0
                        for mobj in tree_obj:
                            if isinstance(mobj, Tree):
                                for nobj in mobj:
                                    m_count += 1
                        # print(f"{time},{put},{puf},{tree_id},{t_objsize},{total_objs},{delta_objs},{old_c},{new_c},{time},{merge_time},{m_count},{reftype}")
                        fulls += f"{time},{put},{puf},{tree_id},{t_objsize},{total_objs},{delta_objs},{old_c},{new_c},{time},{merge_time},{m_count},{reftype}\n"
                    
                elif line.startswith("Remotes"):
                    
                    orc_ind = line.find("old_r_c")
                    if orc_ind > -1:
                        data = line[orc_ind:].split(",")
                        old_c = data[0][8:]
                        new_c = data[1][8:]
                        merge_time = 0.0
                        commit_obj = repo.get(new_c)
                        if not commit_obj:
                            total_objs = 0
                            delta_objs = 0
                            tree_id = "0000000000000000000000000000000000000000"
                            old_c = "0000000000000000000000000000000000000000"
                            new_c = "0000000000000000000000000000000000000000"
                            t_objsize = 0
                            merge_time = 0.0
                            m_count = 0
                            continue
                        tree_obj = commit_obj.tree
                        tree_id = tree_obj.id
                        # print("Remotes:",tree_obj, tree_id)
                        m_count = 0
                        for mobj in tree_obj:
                            if isinstance(mobj, Tree):
                                for nobj in mobj:
                                    m_count += 1
                    else:
                        # time=""
                        # puf = ""
                        # put = ""
                        total_objs = 0
                        delta_objs = 0
                        tree_id = "0000000000000000000000000000000000000000"
                        old_c = "0000000000000000000000000000000000000000"
                        new_c = "0000000000000000000000000000000000000000"
                        # t_objsize = 0
                        merge_time = 0.0
                        m_count = 0
                        # count += 1
                if line == "-----------------------------------------":                
                    time=""
                    puf = ""
                    put = ""
                    total_objs = 0
                    delta_objs = 0
                    tree_id = "0000000000000000000000000000000000000000"
                    old_c = "0000000000000000000000000000000000000000"
                    new_c = "0000000000000000000000000000000000000000"
                    t_objsize = 0
                    merge_time = 0.0
                    m_count = 0
                    count += 1
                elif line == "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx":
                    t_objsize = 0
                    continue
                    # reftype = "remote"
                # if count > 8:
                #     break
        return fulls
    except Exception as e:
            print(count)
            print(f"An error occurred: {e}")

def write_to_csv(ppath: str, peer:str, repo, logfile):
    
    fulls = extract_content(ppath, repo, logfile)
    # print(fulls)
    csvfile = f"{ppath}/{peer}_extract_pull_head.csv"
    # # print("write to ->",csvfile)
    # # print("p_time_from,from,to,treeId,objsize,total_objs,delta_objs,old_c,new_c,p_time_to,merge_time,member_size")
    # # print(fulls)
    with open(csvfile, "+w") as f:
        # f.write("p_time_from,from,to,treeId,objsize,total_objs,delta_objs,old_c,new_c,p_time_to,merge_time,member_size\n")
        f.write(fulls)

def scan_folders(path: str):
    
    for ks in os.listdir(path):
        
        kpath = path + "/" + ks
        
        for peer in os.listdir(kpath):
            if "stats.log" == peer:
                print("stats.log file not a folder")
                continue
        
            ppath = kpath + "/" + peer
            print(ppath)
            # ppath = "/home/abhilash/ThesisCN/master_thesis_revision_2025/rust-crdt-scripts/mesh-arch-testing/pull2/k2/peer1"
            logfile = f"{ppath}/clean_pull8.log"
            repo = Repository(ppath)
            write_to_csv(ppath, peer, repo, logfile)
            # break 
        print()
        # break
    
if __name__ == "__main__":
    
    curr_path = os.getcwd().removesuffix("/analysis") 
    args = sys.argv
    
    if len(args) < 2:
        print("Please pass first argument either 'mesh' or 'tree'")
        exit(1)
    
    if args[1] == "mesh":
        curr_path = curr_path + "/mesh-arch-testing/pull2"
    elif args[1] == "tree":
        curr_path += "/tree-arch-testing/pull"
    else:
        print("Invalid first argument.")
        exit(1)
    
    scan_folders(curr_path)
        