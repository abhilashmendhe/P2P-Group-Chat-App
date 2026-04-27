import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns 
import numpy as np
sns.set_theme()

"""
No GC (blue)

Superlinear growth

Curve bends upward → storage amplification increases over time

This is classic Git behavior:

loose objects

growing object graph

increasing metadata overhead

📌 Key takeaway:

Without GC, using Git as a database leads to unbounded repository growth.

This is a very strong baseline.

🟠🟢🔴 GC @ 128 / 256 / 512

These sawtooth patterns are exactly what we want to see.

Each tooth =

gradual growth → GC → compaction → drop

Differences:

GC @ 128

Smallest peaks

Most frequent drops

Lowest overall repo size

GC @ 256

Moderate peaks

Good balance

GC @ 512

Larger peaks

Fewer GC invocations

Higher steady-state size

📌 Key insight:

Increasing the GC interval trades storage efficiency for fewer maintenance operations.

That’s a textbook systems trade-off.

3️⃣ This plot already answers a research question

You can safely claim:

“Periodic garbage collection bounds repository growth and converts unbounded storage amplification into a stable, oscillatory growth pattern.”

That sentence is thesis-quality.

4️⃣ Two small fixes to make it reviewer-proof
✅ Fix 1: Unit correctness (important)

Your Y-axis says MB, but the scale looks like bytes.

Either:

df['repo_size_mb'] = df['repo_size_bytes'] / (1024 * 1024)


or relabel as:

plt.ylabel("Repository Size (bytes)")


Reviewers will notice this.

✅ Fix 2: Add GC markers (optional but powerful)

For GC runs, mark actual GC points:

for k in [128, 256, 512]:
    for i in range(k, len(df), k):
        plt.axvline(i, alpha=0.1)


Then say:

“Vertical lines indicate garbage collection events.”

This visually ties cause → effect.

5️⃣ How this connects to your latency plots

This plot pairs beautifully with:

Insert latency vs inserts

Latency CDF

Together they show:

GC controls size

GC adds latency spikes

Different k values trade off size vs latency

That’s a complete evaluation loop
"""


def plot_repo_size_vs_inserts(dfs, labels):
    plt.figure(figsize=(12, 6))

    for df, label in zip(dfs, labels):
        plt.plot(
             range(len(df['git-size'])),
            df['git-size'],
            linewidth=2,
            label=label
        )
    for k in [128, 256, 512]:
        for i in range(k, len(df), k):
            plt.axvline(i, alpha=0.1)
    plt.xlabel("Number of Inserts")
    plt.ylabel("Repository Size (MB)")
    plt.title("Repository Size Growth vs Number of Inserts")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig("repo_size_vs_inserts.png")
    plt.show()

def plot_object_count_vs_inserts(dfs, labels):
    plt.figure(figsize=(12, 6))

    for df, label in zip(dfs, labels):
        plt.plot(
            range(len(df['git-size'])),
            # df['git-size'],
            df['count'],
            linewidth=2,
            label=label
        )
    for k in [128, 256, 512]:
        for i in range(k, len(df), k):
            plt.axvline(i, alpha=0.1)
    plt.xlabel("Number of Inserts")
    plt.ylabel("Number of Objects")
    plt.title("Object Count Growth vs Number of Inserts")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig("object_count_vs_inserts.png")
    plt.show()
