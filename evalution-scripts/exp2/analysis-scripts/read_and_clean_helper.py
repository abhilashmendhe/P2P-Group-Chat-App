import pandas as pd
import os
import itertools
def toBytes(x):
    if not isinstance(x, str):
        return 0.0
    if "KiB" in x:
        objspl = x.split(" ")
        nobj = float(objspl[0]) * 1000
        return nobj
    elif "MiB" in x:
        objspl = x.split(" ")
        nobj = float(objspl[0]) * 1000000
        return nobj
    elif len(x) == len("92097d55807612bc90f62dc819ad7a3994c8e57e"):
        return 0.0
    else:
        objspl = x.split(" ")
        return float(objspl[0])
    return 0.0

def read_from_ks(k: str, gossip_type_path: str):
    csvs = []
    for i in range(1, 12):
        
        path = f"{gossip_type_path}/{k}/peer{i}"
        # print(path, gossip_type_path)
        if gossip_type_path == "./mesh/push":
            path = path + "/" + f"peer{i}_extract_push.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
        elif gossip_type_path == "./mesh-gc/push":
            path = path + "/" + f"peer{i}_extract_push.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
            
        elif gossip_type_path == "./mesh/pull":
            path = path + "/" + f"peer{i}_extract_pull_all.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
        elif gossip_type_path == "./mesh-gc/pull":
            path = path + "/" + f"peer{i}_extract_pull_all.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
            
        elif gossip_type_path == "./mesh/pull2":
            path = path + "/" + f"peer{i}_extract_pull_all.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
            
        elif gossip_type_path == "./mesh/pull-push":
            push_path = path + "/" + f"peer{i}_extract_push.csv"
            print(push_path)
            push_df = pd.read_csv(push_path, index_col=False)

            if k=="k2" and i==9:
                print(push_df)
            push_df['epoch'] = push_df['p_time_from'].str.split().str[2].astype(float)

            pull_path = path + "/" + f"peer{i}_extract_pull_all.csv"
            print(pull_path)
            pull_df = pd.read_csv(pull_path, index_col=False)
            pull_df['epoch'] = pull_df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(push_df)
            csvs.append(pull_df)
            
        elif gossip_type_path == "../mesh-arch-testing/push":
            path = path + "/" + f"peer{i}_extract_push.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
        
        elif gossip_type_path == "../mesh-arch-testing/pull3":
            
            path = path + "/" + f"peer{i}_extract_pull_all.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
            

    df = pd.concat(csvs, ignore_index=True)
    df['objsize'] =  pd.to_numeric(df['objsize'], errors='coerce')
    # df['objsize'] = df['objsize'].fillna(0.0)

    df['total_objs'] =  pd.to_numeric(df['total_objs'], errors='coerce')
    # df['total_objs'] = df['total_objs'].astype(float)

    df['delta_objs'] =  pd.to_numeric(df['delta_objs'], errors='coerce')
    # df['delta_objs'] = df['delta_objs'].astype(float)

    df['merge_time'] =  pd.to_numeric(df['merge_time'], errors='coerce')
    # df['merge_time'] = df['merge_time'].astype(float)

    df['member_size'] =  pd.to_numeric(df['member_size'], errors='coerce')
    # df['member_size'] = df['member_size'].astype(float)
    
    df = df.sort_values("epoch")
    df = df.reset_index()

    # df['objsize'] = df['objsize'].apply(toBytes)

    return df

def read_from_tree(gossip_type_path: str):
    csvs = []
    for i in range(1, 12):
        
        path = f"{gossip_type_path}/peer{i}"
        # print(path, gossip_type_path)
        if gossip_type_path == "./tree/push":
            path = path + "/" + f"peer{i}_extract_push.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
            
        elif gossip_type_path == "./tree-gc/push":
            path = path + "/" + f"peer{i}_extract_push.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
            
        elif gossip_type_path == "./tree/pull":
            path = path + "/" + f"peer{i}_extract_pull_all.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df)
            
        elif gossip_type_path == "./tree-gc/pull":
            path = path + "/" + f"peer{i}_extract_pull_all.csv"
            df = pd.read_csv(path, index_col=False)
            df['epoch'] = df['p_time_from'].str.split().str[2].astype(float)
            csvs.append(df) 
            
    df = pd.concat(csvs, ignore_index=True)
    df['objsize'] =  pd.to_numeric(df['objsize'], errors='coerce')
    # df['objsize'] = df['objsize'].fillna(0.0)

    df['total_objs'] =  pd.to_numeric(df['total_objs'], errors='coerce')
    # df['total_objs'] = df['total_objs'].astype(float)

    df['delta_objs'] =  pd.to_numeric(df['delta_objs'], errors='coerce')
    # df['delta_objs'] = df['delta_objs'].astype(float)

    df['merge_time'] =  pd.to_numeric(df['merge_time'], errors='coerce')
    # df['merge_time'] = df['merge_time'].astype(float)

    df['member_size'] =  pd.to_numeric(df['member_size'], errors='coerce')
    # df['member_size'] = df['member_size'].astype(float)
    
    df = df.sort_values("epoch")
    df = df.reset_index()

    # df['objsize'] = df['objsize'].apply(toBytes)

    return df