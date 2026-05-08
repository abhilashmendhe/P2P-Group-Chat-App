import matplotlib.pyplot as plt
import seaborn as sns
sns.set_theme()
import numpy as np

def find_convergence_index_2(
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
    
def plot_cdf(k1_data, k2_data, k3_data, k4_data, tree_data, g_type: str, single="single"):
    plt.figure(figsize=(9, 5))

    datasets = {
        "k = 1": k1_data,
        "k = 2": k2_data,
        "k = 3": k3_data,
        "k = 4": k4_data,
        "tree": tree_data
    }

    for label, data in datasets.items():
        sorted_data = np.sort(data)
        cdf = np.arange(1, len(sorted_data) + 1) / len(sorted_data)

        plt.plot(
            sorted_data,
            cdf,
            linewidth=1,
            marker='d',
            markersize=2,
            label=label
        )

    plt.xlabel("Residue (fraction)", fontsize=11)
    plt.ylabel("CDF of Residue", fontsize=11)
    plt.title(f"CDF of Residue for N = 11 ({g_type})", fontsize=13, fontweight="bold")

    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(title="Fanout (k)")
    plt.tight_layout()

    plt.savefig(f"cdf-{single}-{g_type}.png") # Optional arguments for quality and layout

    plt.show()


def plot_residue_vs_rounds(k1_data, k2_data, k3_data, k4_data, tree_data, g_type: str, single="single", res_type="Residue"):
    plt.figure(figsize=(12, 6))
    rounds = min(len(k1_data), len(k2_data), len(k3_data), len(k4_data), len(tree_data))
    x = range(rounds)
    
    plt.plot(x, k1_data[:rounds], marker='o', linewidth=1, label="k = 1", alpha=0.6, linestyle="--")
    plt.plot(x, k2_data[:rounds], marker='s', linewidth=1, label="k = 2", alpha=0.6, linestyle="--")
    plt.plot(x, k3_data[:rounds], marker='^', linewidth=1, label="k = 3", alpha=0.6, linestyle="--")
    plt.plot(x, k4_data[:rounds], marker='d', linewidth=1, label="k = 4", alpha=0.6, linestyle="--")
    plt.plot(x, tree_data[:rounds], marker='*', linewidth=1, label="tree", alpha=0.8, linestyle="--")

    # plt.plot(x, k1_data[:rounds],  linewidth=1, label="k = 1", alpha=0.7, linestyle="--")
    # plt.plot(x, k2_data[:rounds],  linewidth=1, label="k = 2", alpha=0.7, linestyle="--")
    # plt.plot(x, k3_data[:rounds],  linewidth=1, label="k = 3", alpha=0.7, linestyle="--")
    # plt.plot(x, k4_data[:rounds],  linewidth=1, label="k = 4", alpha=0.7, linestyle="--")
    # plt.plot(x, tree_data[:rounds], linewidth=1, label="tree", alpha=1, linestyle="--")

    # Labels and title
    plt.xlabel("Rounds", fontsize=11)
    plt.ylabel(f"{res_type} (fraction)", fontsize=11)
    plt.title(f"{res_type} vs Rounds (N = 11)", fontsize=13, fontweight="bold")

    # Grid for readability
    plt.grid(True, linestyle='--', alpha=0.5)

    # Legend
    plt.legend(title="Fanout", frameon=True)

    # Optional: annotate final values
    for data, label in zip(
        [k1_data, k2_data, k3_data, k4_data, tree_data],
        ["k1", "k2", "k3", "k4", "tree"]
    ):
        plt.annotate(
            f"{data[-1]:.2f}",
            (x[-1], data[-1]),
            textcoords="offset points",
            xytext=(5, 0),
            ha="left",
            fontsize=9
        )
    
    plt.tight_layout()

    plt.savefig(f"plot-{single}-{g_type}.png") # Optional arguments for quality and layout
    plt.show()


def plot_cum_residue_vs_rounds(k1_data, k2_data, k3_data, k4_data, tree_data, g_type: str, single="single", res_type="Residue"):
    plt.figure(figsize=(12, 6))
    # print(res_type)

    ax = plt.gca()
    
    rounds = min(len(k1_data), len(k2_data), len(k3_data), len(k4_data), len(tree_data))
    x = range(rounds)
    
    plt.plot(x, k1_data[:rounds], marker='o', linewidth=1, label="k = 1", alpha=0.6, linestyle="--")
    plt.plot(x, k2_data[:rounds], marker='s', linewidth=1, label="k = 2", alpha=0.6, linestyle="--")
    plt.plot(x, k3_data[:rounds], marker='^', linewidth=1, label="k = 3", alpha=0.6, linestyle="--")
    plt.plot(x, k4_data[:rounds], marker='d', linewidth=1, label="k = 4", alpha=0.6, linestyle="--")
    plt.plot(x, tree_data[:rounds], marker='*', linewidth=1, label="tree", alpha=0.8, linestyle="--")

    k1ind,k1val = find_convergence_index_2(k1_data, epsilon=1/200, tail_window=20)
    k2ind,k2val = find_convergence_index_2(k2_data, epsilon=1/100, tail_window=20)
    k3ind,k3val = find_convergence_index_2(k3_data, epsilon=1/200, tail_window=20)
    k4ind,k4val = find_convergence_index_2(k4_data, epsilon=1/500, tail_window=20)
    # print(k4ind,k4val)
    treeind,treeval = find_convergence_index_2(tree_data[:rounds], epsilon=1/500,tail_window=20)
    print(k1ind,k2ind,k3ind,k4ind,treeind)
    plt.axvline(k1ind, color='blue',label=f"k1 {k1ind} converge")
    plt.axvline(k2ind, color='orange',label=f"k2 {k2ind} converge")
    plt.axvline(k3ind, color='green',label=f"k3 {k3ind} converge")
    plt.axvline(k4ind, color='red',label=f"k4 {k4ind} converge")
    plt.axvline(treeind,color="purple",label=f"tree {treeind} converge")
    # plt.axhline(np.median(k1_data[:rounds]),color="r")
    # plt.axhline(np.median(k2_data[:rounds]),color="b")
    # plt.axhline(np.median(k3_data[:rounds]),color="g")
    # plt.axhline(np.median(k4_data[:rounds]),color="y")
    # plt.axhline(np.median(tree_data[:rounds]),color="gray")

    current_ticks = list(ax.get_xticks())
    # Add the new vertical line position to the list of ticks
    new_ticks = sorted(current_ticks + [k1ind,k2ind,k3ind,k4ind,treeind])
    new_ticks.pop(0)
    print(new_ticks)
    # 4. Set the new tick locations
    ax.set_xticks(new_ticks)
    # ax.tick_params(axis='x', labelrotation=90)
    # Labels and title
    plt.xlabel("Rounds", fontsize=11)
    plt.ylabel(f"{res_type} (fraction)", fontsize=11)
    plt.title(f"{res_type} vs Rounds (N = 11)", fontsize=13, fontweight="bold")

    # Grid for readability
    plt.grid(True, linestyle='--', alpha=0.5)

    # Legend
    plt.legend(title="Fanout", frameon=True)

    # Optional: annotate final values
    for data, label in zip(
        [k1_data, k2_data, k3_data, k4_data, tree_data],
        ["k1", "k2", "k3", "k4", "tree"]
    ):
        plt.annotate(
            f"{data[-1]:.2f}",
            (x[-1], data[-1]),
            textcoords="offset points",
            xytext=(5, 0),
            ha="left",
            fontsize=9
        )
    
    plt.tight_layout()
    plt.xticks(rotation=90, ha='right')
    # print(plt.labels())
    # print(plt)
    # ax.set_xticklabels(plt.labels(), rotation=45, ha='right')
    plt.savefig(f"plot-cum-residue-{single}-{g_type}.png") # Optional arguments for quality and layout
    plt.show()
