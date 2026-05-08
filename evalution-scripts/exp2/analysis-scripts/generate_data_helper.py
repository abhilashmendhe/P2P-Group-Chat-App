import pandas as pd
import os
import itertools
import numpy as np

def find_convergence_index(
    data,
    epsilon=1e-3,
    tail_window=20
):
    data = np.array(data)
    
    steady_value = np.mean(data[-tail_window:])

    for i in range(len(data)):
        if np.all(np.abs(data[i:] - steady_value) <= epsilon):
            return i, steady_value

    return None, steady_value

def nodes_informed(data):

    new_data = [0 for i in range(len(data))]
    for i in range(len(data)):
        new_data[i] = abs(11 * (1-data[i]))
    return new_data

def get_p1_p2_data(df):
    p1_data = []
    p2_data = []
    clear_p1_data = []
    clear_p2_data = []
    tree_pkv = {}
    tree_clear_kv = {}
    traffic_kv = {}
    

    all_timestamps = []
    all_timestamps.append(df['epoch'][0])
    start_uxt = df['epoch'][0] + 5000
    
    for index, row in df.iterrows():
        pf = row['from']
        pt = row['to']
        treeId = row['treeId']
        
        if row['epoch'] < start_uxt:    
            if not treeId in tree_pkv:
                tree_pkv[treeId] = set()
                
            tree_pkv[treeId].add(pt)
            tree_pkv[treeId].add(pf)
            
            if not treeId in tree_clear_kv:
                tree_clear_kv[treeId] = set()
            tree_clear_kv[treeId].add(pt)
            tree_clear_kv[treeId].add(pf)
            
            traffic_kv[pf] = traffic_kv.get(pf, 0) + 1
        else:
            tc = 0
            for k,v in tree_pkv.items():
                tc += 1-len(v)/11
            ftc = tc / len(tree_pkv)
            p1_data.append(tc)
            p2_data.append(ftc)

            clear_tc = 0
            for k,v in tree_clear_kv.items():
                clear_tc += 1-len(v)/11
            clear_ftc = clear_tc / len(tree_clear_kv)
            clear_p1_data.append(clear_tc)
            clear_p2_data.append(clear_ftc)
            
            tree_clear_kv.clear() # clear the dict..
            
            if not treeId in tree_pkv:
                tree_pkv[treeId] = set()
            tree_pkv[treeId].add(pt)
            tree_pkv[treeId].add(pf)

            if not treeId in tree_clear_kv:
                tree_clear_kv[treeId] = set()

            tree_clear_kv[treeId].add(pt)
            tree_clear_kv[treeId].add(pf)
            
            traffic_kv[pf] = traffic_kv.get(pf, 0) + 1
            all_timestamps.append(start_uxt)
            
            start_uxt += 5000
    traffic_count = 0
    for k,v in traffic_kv.items():
        traffic_count = traffic_count + v/11

    traffic_count /= len(traffic_kv)

    c_ind, c_value = find_convergence_index(
        p2_data,
        epsilon=1e-3,
        tail_window=20
    )
    return clear_p1_data, clear_p2_data, p1_data, p2_data, all_timestamps, traffic_count, df['objsize'].sum(), df['total_objs'].sum(), df['delta_objs'].sum(), df['merge_time'].mean(), c_ind, c_value