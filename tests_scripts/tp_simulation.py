#!/usr/bin/env python3
"""
crdt_sim.py
Simple discrete-round simulator for add-set CRDT epidemic dissemination.
Produces plots for: residue over rounds, normalized traffic per node, and latency histogram.

Usage:
    python crdt_sim.py

Adjust parameters in the CONFIG block below.
"""

import random
import math
import statistics
from collections import defaultdict
import matplotlib.pyplot as plt
import numpy as np

# -------------------- CONFIG --------------------
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

N = 7                  # number of nodes (set to 3 to mimic your log chain)
K = 2                  # neighbor degree (k)
ROUNDS = 60            # number of rounds to simulate
FANOUT = 1             # how many neighbors chosen per round to push/pull
PROTOCOL = "push"      # "push" | "pull" | "hybrid"
UPDATES_AT_ROUND = {1: [(0, "u0")],   # dict round -> list of (origin_node, update_id)
                    3: [(2, "u1")],   # add more updates at different rounds to simulate concurrent writes
                    5: [(0, "u2")]}
UPDATE_SIZE_KB = 4.5   # assumed per-update size (KiB); could vary per update
BATCH_OVERHEAD_KB = 0.1 # per-message overhead
# ------------------------------------------------

# Build random partial-mesh adjacency
nodes = list(range(N))
adj = {i: set() for i in nodes}
# Ensure connectivity: start from chain
for i in range(N-1):
    adj[i].add(i+1)
    adj[i+1].add(i)
# Add random edges until degree >= K
for i in nodes:
    while len(adj[i]) < K:
        j = random.choice(nodes)
        if j != i:
            adj[i].add(j)
            adj[j].add(i)

# Simulation state
known = {i: set() for i in nodes}           # set of update_ids known by node
created_at = dict()                         # update_id -> round created
origin_of = dict()
traffic_by_round_bytes = [0.0 for _ in range(ROUNDS+1)]
residue_by_round = []
per_update_seen_rounds = defaultdict(dict)  # update_id -> node -> round first seen

def send_message(sender, receiver, update_ids):
    """Account traffic (bytes) for sending update_ids from sender to receiver."""
    if not update_ids:
        return 0.0
    size_kb = len(update_ids) * UPDATE_SIZE_KB + BATCH_OVERHEAD_KB
    bytes_sent = size_kb * 1024.0
    return bytes_sent

# Helper: choose neighbors
def choose_neighbors(node, count):
    nbrs = list(adj[node])
    if not nbrs:
        return []
    return random.sample(nbrs, min(count, len(nbrs)))

# Simulation main loop
all_updates = set()
for r in range(1, ROUNDS+1):
    # create new updates scheduled for this round
    if r in UPDATES_AT_ROUND:
        for origin, uid in UPDATES_AT_ROUND[r]:
            created_at[uid] = r
            origin_of[uid] = origin
            all_updates.add(uid)
            # origin immediately knows its own update in same round
            known[origin].add(uid)
            per_update_seen_rounds[uid][origin] = r

    # each node builds outgoing messages this round depending on protocol
    outgoing = []  # tuples (sender, receiver, set_of_update_ids_to_send)
    if PROTOCOL == "push" or PROTOCOL == "hybrid":
        # push known-but-new updates to neighbors
        for i in nodes:
            # push all known updates (could optimize only new ones; we send full set here)
            nbrs = choose_neighbors(i, FANOUT)
            for nb in nbrs:
                # in push, send the set of updates sender has that receiver likely misses
                to_send = known[i] - known[nb]
                if to_send:
                    outgoing.append((i, nb, set(to_send)))
    if PROTOCOL == "pull" or PROTOCOL == "hybrid":
        # pull: each node asks neighbors for what they have and pulls missing
        for i in nodes:
            nbrs = choose_neighbors(i, FANOUT)
            for nb in nbrs:
                # node i will request peer nb's summary; in a discrete sim we directly model the result:
                to_pull = known[nb] - known[i]
                if to_pull:
                    outgoing.append((nb, i, set(to_pull)))

    # deliver messages and account traffic
    round_total_bytes = 0.0
    # To avoid double-application conflicts in hybrid, collect delivers then apply
    deliveries = []
    for sender, receiver, uids in outgoing:
        bytes_sent = send_message(sender, receiver, uids)
        round_total_bytes += bytes_sent
        deliveries.append((receiver, uids))
    traffic_by_round_bytes[r] = round_total_bytes

    # Apply deliveries: at end of round, nodes learn new updates
    for receiver, uids in deliveries:
        new_uids = uids - known[receiver]
        if new_uids:
            for uid in new_uids:
                known[receiver].add(uid)
                # mark first-seen round if first time
                if receiver not in per_update_seen_rounds[uid]:
                    per_update_seen_rounds[uid][receiver] = r

    # compute residue at round r
    union_updates = set().union(*[known[i] for i in nodes])
    union_size = len(union_updates)
    residues = [union_size - len(known[i]) for i in nodes]
    residue_by_round.append( (r, union_size, residues) )

    # quick early exit if converged
    if union_size > 0 and all(len(known[i]) == union_size for i in nodes):
        # fill rest of traffic_by_round with zeros
        for rr in range(r+1, ROUNDS+1):
            traffic_by_round_bytes[rr] = 0.0
        print(f"Converged at round {r}.")
        break

# -------------------- ANALYSIS & PLOTS --------------------
rounds = list(range(1, len(residue_by_round)+1))
union_sizes = [x[1] for x in residue_by_round]
avg_residue = [sum(x[2])/N for x in residue_by_round]
max_residue = [max(x[2]) for x in residue_by_round]
normalized_traffic_kb = [traffic_by_round_bytes[r]/1024.0 / N for r in range(len(residue_by_round)+1)]

# Per-update latencies
latencies = []
for uid in all_updates:
    if uid not in per_update_seen_rounds:
        continue
    first = min(per_update_seen_rounds[uid].values())
    # compute latency to reach all nodes that eventually saw it
    for node, seenr in per_update_seen_rounds[uid].items():
        latencies.append(seenr - first)

# Print summary stats
print("Experiment summary:")
print(" Nodes:", N, "Protocol:", PROTOCOL, "K:", K, "Fanout:", FANOUT)
print(" Created updates:", sorted(list(all_updates)))
print(" Total traffic KB (all rounds): {:.2f} KiB".format(sum(traffic_by_round_bytes)/1024.0))
print(" Normalized traffic (avg per node) KB/round sample (first 10):", np.round(normalized_traffic_kb[1:11],3))
if latencies:
    print(" Latency mean {:.2f} rounds, median {:.2f}, stdev {:.2f}".format(statistics.mean(latencies),
                                                                             statistics.median(latencies),
                                                                             statistics.pstdev(latencies)))
else:
    print(" No latencies recorded (no updates).")

# --- Plots ---
plt.figure(figsize=(12, 4))
plt.subplot(1,3,1)
plt.plot(rounds, avg_residue, marker='o')
plt.title("Avg Residue vs Round")
plt.xlabel("Round")
plt.ylabel("Avg residue (#missing updates)")

plt.subplot(1,3,2)
plt.plot(range(len(normalized_traffic_kb)), normalized_traffic_kb, marker='o')
plt.title("Normalized Traffic per Node (KiB) vs Round")
plt.xlabel("Round")
plt.ylabel("KiB per node")

plt.subplot(1,3,3)
if latencies:
    plt.hist(latencies, bins=range(0, max(latencies)+2))
    plt.title("Per-update latency (rounds)")
    plt.xlabel("Rounds")
    plt.ylabel("Count")
else:
    plt.text(0.1, 0.5, "No latencies", fontsize=12)
    plt.axis('off')

plt.tight_layout()
plt.show()
