import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns 
import numpy as np
sns.set_theme()

def plot_push_latency_all(dfs, labels):
    plt.figure(figsize=(12, 6))

    y_final = 0.0
    for df, label in zip(dfs, labels):
        inserts = range(len(df))
        y_final += df['dif-push-time'].mean()
        plt.plot(
            inserts,
            df['dif-push-time'],
            alpha=0.6,
            linewidth=1.5,
            label=label
        )
    ax = plt.gca()
    y_final /= len(dfs)
    ax.axhline(y=y_final, color='black', linestyle='--', linewidth=1, label=f"line at {y_final:.3f} s.")
    
    yticks = list(ax.get_yticks()) + [y_final]
    ax.set_yticks(sorted(set(yticks)))
    ax.set_yticklabels([f"{y:.2f}" for y in ax.get_yticks()])

    plt.xlabel("Number of Push")
    plt.ylabel("Push Latency (seconds)")
    plt.title("Push Latency vs Number of Inserts")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig("push_latency_all_plots.jpeg")
    plt.show()

def plot_push_latency_ma_all(dfs, labels, window=50):
    plt.figure(figsize=(12, 6))

    for df, label in zip(dfs, labels):
        ma = df['dif-push-time'].rolling(window).mean()
        # ma = np.cumsum(df['dif-push-time'])
        plt.plot(ma, linewidth=2, label=f"{label} (MA={window})", alpha=.9,
            linestyle=":")

    plt.xlabel("Number of Push")
    plt.ylabel("Push Latency (seconds)")
    plt.title("Smoothed Push Latency vs Number of Inserts")
    plt.legend()
    plt.grid(alpha=0.6)
    plt.tight_layout()
    plt.savefig("moving_average_push_comparison.jpeg")
    plt.show()

def plot_push_latency_cdf_all(dfs, labels):
    plt.figure(figsize=(8, 6))

    for df, label in zip(dfs, labels):
        data = np.sort(df['dif-push-time'].dropna())
        cdf = np.arange(1, len(data) + 1) / len(data)
        plt.plot(data, cdf, linewidth=2, label=label)

    # for p in [0.25, 0.5, 0.75]:
    #     plt.axhline(p, linestyle='--', alpha=0.3)
    for p in [0.5, 0.90, 0.95, 0.99]:
        plt.axhline(p, linestyle='--', alpha=0.5)

    plt.xlabel("Push Latency (seconds)")
    plt.ylabel("Fraction of push latency")
    plt.title("CDF of Push Latency")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig("cdf_push_latency_all.jpeg")
    plt.show()
