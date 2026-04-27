import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns 
import numpy as np
# sns.set_theme()
"""
“Insertion latency in a Git-backed object store increases monotonically with repository growth and exhibits heavy-tailed behavior 
even in the absence of explicit garbage collection.”
"To provide concrete reference points, we additionally sample insertion latency at exponentially increasing insert counts (128, 256, 512, …). 
These samples capture how latency evolves as the repository grows and are used for cross-configuration comparison."

Add
---
Mean latency

Median latency

95th / 99th percentile

Max latency
"""
def plot_scatter_with_sampling(x, y):
    plt.figure(figsize=(12, 6))

    y_desc = y.describe()
    
    # Main latency curve
    plt.plot(x, y, alpha=0.4, linewidth=1, label="Insert latency")
    
    # Sampling points
    sample_points = [128, 256, 512, 1024, 2048, 4096, 8192]
    sample_x = []
    sample_y = []

    for p in sample_points:
        if p < len(y):
            sample_x.append(p)
            sample_y.append(y[p])

    # Plot sampled markers
    plt.scatter(
        sample_x,
        sample_y,
        color='purple',
        s=80,
        zorder=3,
        label=f"Latency at {sample_points} inserts"
    )

    
    # Reference latency line
    # plt.axhline(y=0.25, color='r', linestyle='--', linewidth=2, label="0.25s reference")
    # yticks = list(ax.get_yticks())
    # yticks.append(0.25)
    # ax.set_yticks(sorted(set(yticks)))
    ax = plt.gca()

    # for i, txt in enumerate(sample_points):
        # ax.annotate(txt, (sample_x[i], sample_y[i]))
    
    ax.axhline(y=0.25, color='r', linestyle='--', linewidth=2, label="line at 0.25 s.")
    # ax.axhline(y=y_desc['25%'], color='r', linestyle='--', linewidth=1, label=f"at 25% ({y_desc['25%']})")
    # ax.axhline(y=y_desc['50%'], color='r', linestyle='--', linewidth=1, label=f"at 50% ({y_desc['50%']})")
    # ax.axhline(y=y_desc['75%'], color='r', linestyle='--', linewidth=1, label=f"at 75% ({y_desc['75%']})")
    
    
    yticks = list(ax.get_yticks()) + [0.25]
    ax.set_yticks(sorted(set(yticks)))
    ax.set_yticklabels([f"{y:.2f}" for y in ax.get_yticks()])
    
    plt.xlabel("Number of Inserts")
    plt.ylabel("Insert Latency (seconds)")
    plt.title("Insert Latency without GC")

    plt.legend()
    plt.tight_layout()
    plt.savefig("latency_with_nogc.jpeg")
    plt.show()

"""
“Periodic garbage collection introduces brief maintenance events that 
reduce accumulated insertion latency by repacking objects, visible as latency resets following each GC invocation.”
"""
def get_outliers(pd_series, p1=.25, p2=.75):
    
    Q1 = pd_series.quantile(p1)
    Q3 = pd_series.quantile(p2)
    IQR = Q3 - Q1
    
    # Determine outlier boundaries
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR

    return pd_series[(pd_series < lower_bound) | (pd_series > upper_bound)]
    
def plot_latency_with_gc(x, y, k, p1=.25, p2=.75):
    
    plt.figure(figsize=(12, 6))

    ax = plt.gca()
    # Raw latency
    plt.plot(x, y, alpha=0.5, linewidth=1, label="Insert latency")
    outliers = get_outliers(y, p1, p2)
    ax.vlines(outliers.index, y.median(), outliers, color='purple', linewidth=0.5)
    # Optional: Add points at the top of the lines for clarity
    ax.plot(outliers.index, outliers, 'o', color='blue', markersize=3)        
    
    # GC markers
    max_x = max(x)
    gc_points = range(k, max_x, k)

    for gc in gc_points:
        plt.axvline(gc, color='red', linestyle='--', alpha=0.35, linewidth=1)

    plt.xlabel("Number of Inserts")
    plt.ylabel("Insert Latency (seconds)")
    plt.title(f"Insert Latency with GC Events (k = {k})")

    plt.legend()
    plt.tight_layout()
    plt.savefig(f"latency_with_gc_k{k}.jpeg")
    plt.show()
