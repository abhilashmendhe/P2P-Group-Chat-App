import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns 
import numpy as np
sns.set_theme()

def plot_bar_for_db_sizes(dfs, labels):
    fig, axs = plt.subplots(1, 2, figsize=(10, 4.5))

    final_size = []
    final_objs = []

    for df in dfs:
        final_size.append(df['git-size'].iloc[-2])
        final_objs.append(df['count'].iloc[-2])

    # create new labels with size info
    size_labels = [f"{lab}\n({size/1000000:.3f} Mb)" for lab, size in zip(labels, final_size)]
    objs_labels = [f"{lab}\n({size})" for lab, size in zip(labels, final_objs)]
    
    # Repo size bar plot
    axs[0].bar(size_labels, final_size, color="purple")
    axs[0].set_title("Total Git Repository Size")
    axs[0].set_ylabel("Repository Size (bytes)")

    # Object count bar plot
    axs[1].bar(objs_labels, final_objs, color='skyblue')
    axs[1].set_title("Total Git Object Count")
    axs[1].set_ylabel("Number of Objects")

    plt.setp(axs[0].get_xticklabels(), rotation=45, ha='right')
    plt.setp(axs[1].get_xticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig("bar_plots_of_size_counts.jpeg")
    plt.show()
