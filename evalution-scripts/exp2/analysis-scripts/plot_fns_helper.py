import matplotlib.pyplot as plt
import seaborn as sns
sns.set_theme()
import numpy as np

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
    plt.ylabel("CDF  P(X ≤ x)", fontsize=11)
    plt.title(f"CDF of Residue for N = 11 ({g_type})", fontsize=13, fontweight="bold")

    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(title="Fanout (k)")
    plt.tight_layout()

    plt.savefig(f"cdf-{single}-{g_type}.png") # Optional arguments for quality and layout

    plt.show()


def plot_function(k1_data, k2_data, k3_data, k4_data, tree_data, g_type: str, single="single"):
    plt.figure(figsize=(9, 5))

    # print(len(k1_data), len(k2_data), len(k3_data), len(k4_data))
    # rounds = range(len(k1_data))
    # rounds = min(len(k1_data), len(k2_data), len(k3_data), len(k4_data),len(tree_data))
    rounds = min(len(k1_data), len(k2_data), len(k3_data), len(k4_data), len(tree_data))
    x = range(rounds)
    
    plt.plot(x, k1_data[:rounds], marker='o', linewidth=2, label="k = 1")
    plt.plot(x, k2_data[:rounds], marker='s', linewidth=2, label="k = 2")
    plt.plot(x, k3_data[:rounds], marker='^', linewidth=2, label="k = 3")
    plt.plot(x, k4_data[:rounds], marker='d', linewidth=2, label="k = 4")
    plt.plot(x, tree_data[:rounds], marker='d', linewidth=2, label="tree")

    # Labels and title
    plt.xlabel("Rounds", fontsize=11)
    plt.ylabel("Residue (fraction)", fontsize=11)
    plt.title("Residue vs Rounds (N = 11)", fontsize=13, fontweight="bold")

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
