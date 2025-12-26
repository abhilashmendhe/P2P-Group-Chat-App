# cat ../push/k1/peer1/peer1_PUSH.log | grep -iE  "\-\-" | wc -l

import os 

curr_path = os.getcwd().removesuffix("/analysis") + "/push"
# print(curr_path)

for ks in os.listdir(curr_path):
    
    kpath=curr_path + "/" + ks 
    # print(kpath)
    for peer in os.listdir(kpath):
        
        if "stats.log" == peer:
            print("stats.log file not a folder")
            continue
        
        ppath = kpath + "/" + peer
        
        # Read file path
        logfile = f"{ppath}/{peer}_PUSH.log"
        
        fulls = ""
        try:
            with open(logfile, 'r') as file:
                count = 0
                new_line = ""
                for line in file:
                    
                    line = line.strip()
                    if "---" in line:
                        count += 1
                        # break
                        
                        # print(new_line)
                        fulls = fulls + new_line + "\n"
                        
                        new_line = ""
                        
                    elif line.startswith("2025"):
                        linespl = line.split(",")
                        if len(linespl) <= 0:
                            continue
                            
                        news = ""
                        news = news + linespl[0]
                        for s in linespl[1:-1]:
                            ind = s.find(":")
                            if ind >= 0:
                                news = news + "," + s[ind+1:].strip()
                            else:
                                news = news + "," + ""
                        
                        # print(news)
                        new_line += news
                        
                    elif line.startswith("Writing"):
                        
                        linespl = line.split("post-receive:")
                        dlinespl = linespl[0].split("done.")
                        
                        # Extract size of objects
                        s0 = dlinespl[0]
                        ind1 = s0.find(",")
                        ind2 = s0.find("|")
                        objsize = s0[ind1+1:ind2].strip()

                        # Extract num objects and delta objects
                        s1 = dlinespl[1]
                        ind3 = s1.find("l")
                        ind4 = s1.find("(")
                        num_objs = s1[ind3+1:ind4].strip()
                        
                        ind6 = s1.find(")")
                        delta_objs = s1[ind4+6:ind6].strip()
                        
                        # print(objsize, num_objs, delta_objs)
                        new_line = new_line + "," + f"{objsize},{num_objs},{delta_objs},"
                        
                        remote_str = linespl[-1]
                        if remote_str.startswith("Writ"):
                            continue

                        rem_str_spl = remote_str.strip().split(",")
                        
                        post_recv_arr = ""
                        for rr in rem_str_spl:
                            if "push_from" in rr or "first" in rr:
                                continue
                            if rr.strip():
                                col_ind = rr.find(":")
                                if col_ind >= 0:                                
                                    # print(rr[col_ind+1:])
                                    post_recv_arr = post_recv_arr + rr[col_ind+1:] + ","
                                    # post_recv_arr.append(rr[col_ind+1:])
                        # print(post_recv_arr)
                        new_line += post_recv_arr
                        
                    elif "post-receive:" in line:
                        
                        linespl = line.split("post-receive:")
                        
                        remote_str = linespl[-1]
                            
                        find1s = "post-receive:"
                        find2s = "To"
                        
                        f1sind = remote_str.find(find1s)
                        f2sind = remote_str.find(find2s)
                        rem_str_spl = remote_str.strip().split(",")
                        
                        # print(rem_str_spl)
                        post_recv_arr = ""
                        for rr in rem_str_spl:
                            if "push_from" in rr or "first" in rr:
                                continue
                            if rr.strip():
                                col_ind = rr.find(":")
                                if col_ind >= 0:                                
                                    # print(rr[col_ind+1:])
                                    post_recv_arr = post_recv_arr + rr[col_ind+1:] + ","
                                    # post_recv_arr.append(rr[col_ind+1:])
                        # print(post_recv_arr)
                        new_line += post_recv_arr
                        
                # print(count)
        except Exception as e:
            print(f"An error occurred: {e}")
        # Write file path
        csvfile = f"{ppath}/{peer}_extract_push.csv"
        # print("write to ->",csvfile)
        # print("p_time_from,from,to,treeId,objsize,total_objs,delta_objs,old_c,new_c,p_time_to,merge_time,member_size")
        # print(fulls)
        with open(csvfile, "+w") as f:
            f.write("p_time_from,from,to,treeId,objsize,total_objs,delta_objs,old_c,new_c,p_time_to,merge_time,member_size\n")
            f.write(fulls)
        
    #     break
    # break