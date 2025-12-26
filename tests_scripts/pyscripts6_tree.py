import random
import copy
import os 
import subprocess
import time
from datetime import datetime
import _io

SCRIPTDIR = os.path.dirname(os.path.abspath(__file__))
sms_messages = [
    "Hey Bob, are we still on for dinner tonight?",
    "Yep! 7 PM at the usual place work for you?",
    "Perfect. See you then!",
    "Urgent: The meeting time has been moved to 10 AM tomorrow.",
    "Got it, thanks for the heads up Charlie.",
    "Did you remember to pick up milk and eggs?",
    "Just walking into the store now, adding to the list.",
    "Awesome, thanks!",
    "Happy Birthday! Hope you have a fantastic day!",
    "Thanks so much, Grace!",
    "The concert was incredible last night! The lead singer was amazing.",
    "I know! So glad we went. Best show this year.",
    "Can you send me the link to that article we discussed?",
    "Sure, one sec. [Link]",
    "Don't forget the cat food on your way home, please.",
    "Already got it!",
    "The weather forecast for the weekend looks promising for a hike.",
    "Great! Let's plan a route.",
    "My flight's delayed by an hour. I'll get in around 9 PM.",
    "Okay, I'll still be at baggage claim. Drive safe once you're out.",
    "New high score on the game! Beat your record by 200 points!",
    "Challenge accepted! I'm logging in now.",
    "Any recommendations for a good Italian restaurant downtown?",
    "Try 'Luigi's'. Their lasagna is excellent.",
    "Thanks Victor! I'll check it out.",
    "The new project proposal is due on Friday. Are your sections ready?",
    "Almost done. I'll email them to you tonight.",
    "Sounds good, thanks for staying on top of it.",
    "The traffic is terrible on the highway. I'm taking surface streets.",
    "Good call. It's clear over here once you get off the freeway.",
    "Just saw the cutest puppy in the park! Wish I could adopt it.",
    "Aww, don't tempt me! We're not ready for a dog yet.",
    "I know, I know. A girl can dream though!",
    "Did the handyman come by to fix the leaky faucet?",
    "Yes, all fixed now. No more dripping sound!",
    "Fantastic! What did we owe him?",
    "$50. I already paid him.",
    "What time is the gym closing today? Website is down.",
    "Usually 9 PM on weekdays. I'd call to double-check.",
    "Good idea. Thanks, Fiona.",
    "Can you believe that plot twist in the book? I was not expecting it!",
    "Right?! My jaw actually dropped. So good.",
    "Totally worth staying up late to finish it.",
    "Agreed!",
    "Reminder: Dentist appointment tomorrow at 3 PM.",
    "Acknowledged. Thanks for the reminder.",
    "The concert tickets go on sale in 10 minutes! Are you ready?",
    "My finger is on the refresh button! Hope we get good seats.",
    "Good luck to us both!",
    "Got 'em! Section 104!",
    "I accidentally locked my keys in the car. Can you bring the spare set?",
    "On my way, hang tight. Be there in 15.",
    "Thanks so much, you're a lifesaver!",
    "The presentation went really well today. The client seemed happy.",
    "That's great news! Hard work paid off.",
    "Want to grab a coffee this weekend?",
    "Definitely! Saturday morning work for you?",
    "Sounds good, see you then.",
    "My car is making a weird noise. Think I need to take it to the mechanic.",
    "Hope it's nothing serious. Keep me updated.",
    "Will do. Thanks.",
    "I finished the whole season of that show you recommended. It was amazing!",
    "Glad you liked it! The ending was crazy.",
    "Totally! I need the next season now.",
    "Don't forget to take the trash out tonight.",
    "Already done, boss!",
    "Thanks!",
    "Found my old camera from college! Planning to use it this weekend.",
    "Oh nice! Would love to see the pictures you take.",
    "Sure thing, I'll send some over.",
    "The new park near my house is finally open. The playground is great.",
    "We should take the kids there this weekend.",
    "Let's do it!",
    "I'm feeling a bit sick, might work from home tomorrow.",
    "Hope you feel better soon. Take care of yourself.",
    "Thanks, I will.",
    "Can you help me move this heavy box on Saturday?",
    "Yep, what time?",
    "Around noon work?",
    "Perfect.",
    "The package I ordered is delayed. Expected delivery is now next week.",
    "Ugh, that's annoying. What was it?",
    "A book I really wanted to read.",
    "Bummer.",
    "Got a promotion at work today! Celebrating with a big dinner.",
    "Congratulations! That's awesome news!",
    "Thanks so much!",
    "My phone battery is dying. Will call you back in 10 minutes when I can charge it.",
    "Okay, no problem.",
    "Did you see the news about the local election results?",
    "Yeah, surprised by the outcome.",
    "Me too.",
    "Need to buy a new laptop soon. Any recommendations?",
    "Check out the new Dell XPS line. They have great reviews.",
    "Thanks for the tip!",
    "The sunset tonight is beautiful. Wish you were here to see it.",
    "Aw, I bet it is. Enjoy the view.",
    "I am.",
    "Reminder: Pay the electric bill by end of day.",
    "Just paid it online. All set.",
    "Lifesaver, thanks!"
]

def get_curr_time():
    
    now = datetime.now()
    unix_timestamp = time.time()*1000
    formatted_date_time = now.strftime("%Y-%m-%d %T")
    return f"{formatted_date_time} {unix_timestamp}"


def send_message_group(gname, msg, capture_output=True, text=True, check=True):
    try:
        result = subprocess.run(
            [f"{SCRIPTDIR}/../_2_group_ops_api/target/release/send_grp_msg", gname, msg], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        return ["send-message",msg, result.stdout.strip()]
    except subprocess.CalledProcessError as e:
        return ["Error: send-message",msg, e.stderr.strip()]

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
                [f"{SCRIPTDIR}/../_2_group_ops_api/target/release/add_member", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return ["add",gname,mname,result.stdout.strip()]
        elif ops_type == 1:
            result = subprocess.run(
                [f"{SCRIPTDIR}/../_2_group_ops_api/target/release/remove_member", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return ["remove",gname,mname,result.stdout.strip()]
        elif ops_type == 2:
            result = subprocess.run(
                [f"{SCRIPTDIR}/../_2_group_ops_api/target/release/promote", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return ["promote",gname,mname,result.stdout.strip()]
        elif ops_type == 3:
            result = subprocess.run(
                [f"{SCRIPTDIR}/../_2_group_ops_api/target/release/demote", gname, mname], 
                capture_output=capture_output, 
                text=text, 
                check=check
            )
            return ["demote",gname,mname,result.stdout.strip()]
    except subprocess.CalledProcessError as e:
        return [ops_acts[ops_type],gname,mname,e.stderr.strip()]
    
def change_group_name(gname, new_name, new_desc, capture_output=True, text=True, check=True):
    try:
        result = subprocess.run(
            [f"{SCRIPTDIR}/../_2_group_ops_api/target/release/rename_group", gname, new_name, new_desc], 
            capture_output=capture_output, 
            text=text, 
            check=check
        )
        return ["change",gname,new_name,new_desc,result.stdout.strip()]
    except subprocess.CalledProcessError as e:
        print(f"Error executing 'change group description': {e}")
        print(f"Stderr: {e.stderr}")
        return ["Error: change-group",gname,new_name,new_desc,e.stderr.strip()]
    
def run_simulation_add(start, end, gname, arr, f: _io.TextIOWrapper):

    for i in range(start, end):
        num_msgs = random.randint(1, 5)
        for _ in range(num_msgs):
            # send message
            rand_msg = random.choice(sms_messages)
            result = send_message_group(gname, rand_msg, True, True, True)
            # result.insert(0, get_curr_time())
            # print(result)
            wrs = f"{get_curr_time()},{result[-1]},{result[0]}\n"
            f.write(wrs)
            time.sleep(random.random()*0.5)
        
        # add member in group
        if len(arr) <= 0:
            break
        v = arr.pop()
        mname = "peerm" + str(v)
        result:list = group_ops(gname, mname, ops_type=0)    
        # result.insert(0,get_curr_time())
        # print(result)
        wrs = f"{get_curr_time()},{result[-1]},{result[0]}\n"
        f.write(wrs)

        time.sleep(0.3)    

def run_simulation_prd(gname, ops_type, arr, f: _io.TextIOWrapper):

    while arr:
        num_msgs = random.randint(0,4)
        for _ in range(num_msgs):
            # send message
            rand_msg = random.choice(sms_messages)
            result = send_message_group(gname, rand_msg, True, True, True)
            # result.insert(0,get_curr_time())
            # print(result)
            wrs = f"{get_curr_time()},{result[-1]},{result[0]}\n"
            f.write(wrs)

            time.sleep(random.random()*0.5)
        
        # promote / 'remove or demote'
        v = arr.pop()
        mname = "peerm" + str(v)
        if ops_type == 0:  
            result = group_ops(gname, mname, ops_type=2)
            # result.insert(0, get_curr_time())
            # print(result)
            wrs = f"{get_curr_time()},{result[-1]},{result[0]}\n"
            f.write(wrs)

        elif ops_type == 1:
            result = group_ops(gname, mname, ops_type=1)
            # result.insert(0, get_curr_time())
            # print(result)
            wrs = f"{get_curr_time()},{result[-1]},{result[0]}\n"
            f.write(wrs)

        else:
            result = group_ops(gname, mname, ops_type=3)
            # result.insert(0, get_curr_time())
            # print(result)
            wrs = f"{get_curr_time()},{result[-1]},{result[0]}\n"
            f.write(wrs)

        time.sleep(0.35)    

def run_sim(peer_name: str):
    
    # 2.1 Add half members 
    start = 0
    end = 64 
    if peer_name == "peer1" or peer_name == "peer2" or peer_name == "peer3":
        start = 0
        end = start + 64
    elif peer_name == "peer4" or peer_name == "peer5" or peer_name == "peer6" or peer_name == "peer7":
        start = 124
        end = start + 64 
    else:
        start = 248
        end = start + 64
    
    arr = random.sample(range(start, end), 64)
    rdarr = copy.deepcopy(arr)
    print(f"Adding {end-start} members in group: {group_name}")
    run_simulation_add(start, end, group_name, arr, f)
    print(f"1. range: {start} - {end}")
    print("\n\n")
    
    # 2.2 Promote members
    print(f"Promoting members.....")
    parr = random.sample(range(start, end), 20)
    
    print(f"Promoting {20} random members from the group: {group_name}")
    run_simulation_prd(group_name, 0, parr, f)
    print("\n\n")
    
    # 2.3 Add remaining members
    start2 = end + 1
    end2 = start2 + 28
    print("start2: ",start2, "end2:",end2)
    
    arr = random.sample(range(start2, end2), 28)
    print(f"Re-adding {end2-start2} random members in group: {group_name}")
    print(f"2. range: {start} - {end}")
    run_simulation_add(start2, end2, group_name, arr, f)
    print("\n\n")
    
    
    # 2.5 Remove/Demote members
    dem_arr = random.sample(rdarr, 30)
    print(f"Demoting {30} random admins from the group: {group_name}")
    run_simulation_prd(group_name, 1, dem_arr, f)
    rem_arr = random.sample(range(start,end2), 30)
    print(f"Removing {30} random members from the group: {group_name}")
    run_simulation_prd(group_name, 2, rem_arr, f)
    
    time.sleep(2)
    # # 2.6 Add only one group member
    start3 = end2 + 1
    end3 = start3 + 140
    print("start3: ",start3, "end3:",end3)
    arr = random.sample(range(start3, end3), 120)
    print(f"Re-adding {len(arr)} random members in the group: {group_name}")
    run_simulation_add(start3, end3, group_name, arr, f)


if __name__ == "__main__":
    
    group_name = "hiking"

    # 0. Get peer name
    f = open("./.git/.author-cb/git-cb","+r")
    peer_name = f.read()
    f.close()
    
    # 1. Open a file to write
    ops_log_file=f"{peer_name}_ops.log"
    f = open(ops_log_file, "+a")
    
    start_time = time.perf_counter()
    # ############################## START SIMULATION #######################################

    # 2. Run simulation

    run_sim(peer_name)
    
    # ############################## END SIMULATION #########################################
    f.close()
    end_time = time.perf_counter()
    elapsed_time = end_time - start_time

    print(f"Execution time: {elapsed_time:.6f} seconds")
    
