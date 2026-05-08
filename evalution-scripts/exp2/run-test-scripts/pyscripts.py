import random
import string 
import sys 
import os 
import subprocess
import time

SCRIPTDIR = os.path.dirname(os.path.abspath(__file__))

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
            [f"{SCRIPTDIR}/_2_group_ops_api/target/debug/create_group", group_name, group_description], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error executing 'create-group': {e}")
        print(f"Stderr: {e.stderr}")

def send_message_group(gname, msg, capture_output=True, text=True, check=True):
    try:
        result = subprocess.run(
            [f"{SCRIPTDIR}/_2_group_ops_api/target/debug/send_grp_msg", gname, msg], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error executing 'send message group': {e}")
        print(f"Stderr: {e.stderr}")

def add_member(gname, mname, capture_output=True, text=True, check=True):
    try:
        result = subprocess.run(
            [f"{SCRIPTDIR}/_2_group_ops_api/target/debug/add_member", gname, mname], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error executing 'add member to group': {e}")
        print(f"Stderr: {e.stderr}")


def run_simulation(gsize, gname):

    for _ in range(gsize):
        num_msgs = random.randint(3, 5)
        for _ in range(num_msgs):
            
            # send message
            rand_msg = gen_random_msg()
            send_message_group(gname, rand_msg, True, True, True)
            time.sleep(random.random())
        # add member in group
        mname = "peer" + str(int(time.time()))
        add_member(gname, mname)    
        time.sleep(0.25)    

if __name__ == "__main__":
    
    # 0.1 no. of group members
    group_size = int(sys.argv[1])  
    print(f"Testing for group size: {group_size}\n")

    # 0.2 group name
    group_name = sys.argv[2] + str(int(time.time()))
    
    # 0.3 group desc
    group_desc = sys.argv[3]
    
    # 1. Create group hiking
    create_group(group_name, group_desc)
    
    # 2. Run simulation
    run_simulation(group_size, group_name)
    
