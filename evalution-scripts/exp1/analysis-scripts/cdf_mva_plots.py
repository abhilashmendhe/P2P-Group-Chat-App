import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns 
import numpy as np
sns.set_theme()

"""
“GC@128 significantly reduces tail latency”
“No-GC exhibits a heavy tail with rare but extreme delays”
“At the 95th percentile, GC@256 reduces latency by X% compared to no GC.”
"""
def plot_cdf(latency_dict):
    """
    latency_dict = {
        "no GC": y_no_gc,
        "GC@128": y_gc_128,
        "GC@256": y_gc_256,
        "GC@512": y_gc_512
    }
    """
    plt.figure(figsize=(8, 6))

    for label, y in latency_dict.items():
        sorted_y = np.sort(y)
        cdf = np.arange(1, len(sorted_y) + 1) / len(sorted_y)
        plt.plot(sorted_y, cdf, label=label)

    plt.xlabel("Insert Latency (seconds)")
    plt.ylabel("Fraction of Insert latency")
    plt.title("CDF of Insert Latency")
    # plt.axhline(0.95, color='gray', linestyle='--', alpha=0.6)
    for p in [0.5, 0.90, 0.95, 0.99]:
        plt.axhline(p, linestyle='--', alpha=0.5)
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig("cdf_insert_latency_all.jpeg")
    plt.show()



"""
“Figure X compares insertion latency across configurations using a uniform moving average of 50 inserts. 
Periodic garbage collection significantly reduces long-term insertion latency, 
with smaller intervals providing lower steady-state latency at the cost of more frequent maintenance.”
"""
def moving_average(y, window):
    y = np.asarray(y)
    return np.convolve(y, np.ones(window) / window, mode="valid")

def plot_all_moving_averages(
    df_nogc,
    df_gc_128,
    df_gc_256,
    df_gc_512,
    window=50
):
    plt.figure(figsize=(12, 6))

    configs = {
        "No GC": df_nogc,
        "GC @ 128": df_gc_128,
        "GC @ 256": df_gc_256,
        "GC @ 512": df_gc_512
    }

    for label, df in configs.items():
        latency = df['dif-add-mem-time'].values
        latency_ma = moving_average(latency, window)
        # latency_ma = np.cumsum(latency)
        x_ma = range(window, window + len(latency_ma))

        plt.plot(
            x_ma,
            latency_ma,
            linewidth=2,
            label=label,
            alpha=.8,
            linestyle=":"
        )

    # # Reference latency (optional)
    # plt.axhline(
    #     y=0.25,
    #     color='gray',
    #     linestyle='--',
    #     linewidth=1.5,
    #     label="0.25s reference"
    # )

    plt.xlabel("Number of Inserts")
    plt.ylabel("MA Insert Latency (seconds)")
    plt.title(f"Smoothed Insert Latency (Moving Average, window = {window})")

    plt.legend()
    plt.grid(alpha=0.6)
    plt.tight_layout()
    plt.savefig("moving_average_inserts_comparison.jpeg")
    plt.show()

def plot_cumulative_time(df_nogc, df_gc_128, df_gc_256, df_gc_512):
    plt.figure(figsize=(12, 6))

    cs_128 = df_gc_128['dif-add-mem-time'].cumsum()
    cs_256 = df_gc_256['dif-add-mem-time'].cumsum()
    cs_512 = df_gc_512['dif-add-mem-time'].cumsum()
    cs_no  = df_nogc['dif-add-mem-time'].cumsum()

    plt.plot(range(len(cs_no)), cs_no,  label="No GC", alpha=0.6)
    plt.plot(range(len(cs_128)), cs_128, label="GC@128", alpha=0.6)
    plt.plot(range(len(cs_256)), cs_256, label="GC@256", alpha=0.6)
    plt.plot(range(len(cs_512)), cs_512, label="GC@512", alpha=0.6)

    plt.xlabel("Number of Inserts")
    plt.ylabel("Cumulative Time (seconds)")
    plt.title("Cumulative Insertion Time")

    plt.legend()
    plt.tight_layout()
    plt.show()
