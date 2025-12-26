import random
import string 
import sys 
import os 
import subprocess
import time
from datetime import datetime

SCRIPTDIR = os.path.dirname(os.path.abspath(__file__))

def get_curr_time():
    
    now = datetime.now()
    unix_timestamp = time.time()*1000
    formatted_date_time = now.strftime("%Y-%m-%d %T")
    return f"{formatted_date_time} {unix_timestamp}"

def gen_random_msg():
    s = ""
    for _ in range(random.randint(3,9)):
        msg_len = random.randint(3,8)
        word = ''.join(random.choices(string.ascii_letters+string.digits, k=msg_len))
        s = s + word + " "
    return s

def create_group(group_name, group_description, capture_output=True, text=True, check=True):
    try:
        result = subprocess.run(
            [f"{SCRIPTDIR}/_2_group_ops_api/target/release/create_group", group_name, group_description], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Error executing 'create-group': {e.stderr}"
    
def send_message_group(gname, msg, capture_output=True, text=True, check=True):
    try:
        result = subprocess.run(
            [f"{SCRIPTDIR}/_2_group_ops_api/target/release/send_grp_msg", gname, msg], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Error executing 'send message group': {e.stderr}"
    
def group_ops(gname, mname, capture_output=True, text=True, check=True, ops_type=0):
    ops_acts = {
        0: "Error: add-member",
        1: "Error: remove-member",
        2: "Error: promote-member",
        3: "Error: demote-member",
    }
    try:
        if ops_type == 0:
            result = subprocess.run(
                [f"{SCRIPTDIR}/_2_group_ops_api/target/release/add_member", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return result.stdout
        elif ops_type == 1:
            result = subprocess.run(
                [f"{SCRIPTDIR}/_2_group_ops_api/target/release/remove_member", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return result.stdout
        elif ops_type == 2:
            result = subprocess.run(
                [f"{SCRIPTDIR}/_2_group_ops_api/target/release/promote", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return result.stdout
        elif ops_type == 3:
            result = subprocess.run(
                [f"{SCRIPTDIR}/_2_group_ops_api/target/release/demote", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return result.stdout
    except subprocess.CalledProcessError as e:
        return f"{ops_acts[ops_type]} : {e.stderr}"
    
def change_group_name(gname, new_name, new_desc, capture_output=True, text=True, check=True):
    try:
        result = subprocess.run(
            [f"{SCRIPTDIR}/_2_group_ops_api/target/release/rename_group", gname, new_name, new_desc], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Error executing 'change group name' : {e.stderr}"
    
def run_simulation_add(start, end, gname):

    for i in range(start, end):
        num_msgs = random.randint(1, 7)
        for _ in range(num_msgs):
            # send message
            rand_msg = gen_random_msg()
            res = send_message_group(gname, rand_msg, True, True, True)
            if res:
                print(f"{get_curr_time()}, {res}")
            time.sleep(random.random()*0.5)
        
        # add member in group
        mname = "peerm" + str(i)
        res = group_ops(gname, mname, ops_type=0)    
        if res:
            print(f"{get_curr_time()}, {res}")
        time.sleep(0.25)    

def run_simulation_prd(start, end, gname, ops_type):

    # arr = list(range(start, end))
    arr = random.sample(range(start, end), 15)
    ind = 0
    while arr:
        num_msgs = random.randint(0,5)
        for _ in range(num_msgs):
            # send message
            rand_msg = gen_random_msg()
            res = send_message_group(gname, rand_msg, True, True, True)
            if res:
                print(f"{get_curr_time()}, {res}")
            time.sleep(random.random()*0.5)
        
        # promote / 'remove or demote'
        v = arr.pop()
        mname = "peerm" + str(v)
        if ops_type == 0:  
            res = group_ops(gname, mname, ops_type=2)
            if res:
                print(f"{get_curr_time()}, {res}")
        else:
            # perform either remove or demote
            if ind % 2 == 0:
                res = group_ops(gname, mname, ops_type=1)
                if res:
                    print(f"{get_curr_time()}, {res}")
            else:
                res = group_ops(gname, mname, ops_type=3)
                if res:
                    print(f"{get_curr_time()}, {res}")
            ind += 1
        
        time.sleep(0.25)    

if __name__ == "__main__":
    
    # 0.1 no. of group members
    group_size = int(sys.argv[1])  
    
    if group_size < 32:
        print(f"Group size must be greater than 32")
        exit(1)
        
    print(f"Testing for group size: {group_size}\n")

    # 0.2 group name
    # group_name = sys.argv[2] + str(int(time.time()))
    group_name = sys.argv[2]
    
    # 0.3 group desc
    group_desc = sys.argv[3]
    
    # 1. Create group hiking
    print(f"Group: {group_name} created!!!")
    create_group(group_name, group_desc)
    print()
    # 2. Run simulation 4 times
    
    # 2.1 Add half members 
    start = 0
    end = group_size // 2
    print(f"Adding {end-start} members in group: {group_name}")
    run_simulation_add(start, end, group_name)
    # print(f"1. range: {start} - {end}")
    print("\n\n")
    
    # # 2.2 Promote members
    print(f"Promoting members.....")
    run_simulation_prd(0, 15, group_name, 0)
    print("\n\n")
    
    # 2.3 Add remaining members
    more_half_gsize = end // 2
    start = end
    end = start + more_half_gsize
    print(f"Adding {end-start} members in group: {group_name}")
    # print(f"2. range: {start} - {end}")
    run_simulation_add(start, end, group_name)
    print("\n\n")
    
    # 2.4. Chnage group desc
    ngroup_name = "g" + str(int(time.time()))
    ngroup_desc = "with Phds and colleagues"
    res = change_group_name(group_name, ngroup_name,  ngroup_desc)
    if res:
        print(f"{get_curr_time()}, {res}")
    group_name = ngroup_name
    print("\n\n")
    time.sleep(5)
    
    # 2.5. Add remaining
    start = end 
    end = group_size
    # print(f"3. range: {start} - {end}")
    run_simulation_add(start, end, group_name)
    
    
    # 2.5 Remove/Demote members
    run_simulation_prd(0, end, group_name, 1)
    
    time.sleep(5)
    # 2.6 Add only one group member
    run_simulation_add(1000, 1001, group_name)