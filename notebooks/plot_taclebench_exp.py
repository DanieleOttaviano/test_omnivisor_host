# All imports
import os
import sys
import seaborn as sns
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from math import floor, ceil
from matplotlib.patches import Rectangle
from matplotlib.patches import FancyArrowPatch

plots_fig_size = (10, 6)
plots_fig_size_alt = (9, 6)

labels_fontsize = 24
ticks_fontsize = 21
plot_linewidts = 2.5

core_color = {
    'RPU': '#F9665E',
    'RISCV': '#799FCB',
    'Constrained': '#8BB3B5' #'#80179E'
}

isolation_style = {
    'None': {
        'RPU': '-',
        'RISCV': '-',
    },
    'Spatial': {
        'RPU': '--',
        'RISCV': '--',
    },
    'Full': {
        'RPU': (0, (1, 3)),
        'RISCV': (2, (1, 3)),
    },
}

disturb_color = {
    'APU': '#A88EB3',
    'RPU1': '#FFCC99',
    'FPGA1': '#8BB3B5',
    'FPGA2': '#ADCECF',
    'FPGA': '#8BB3B5'
}

activation_colors = {
    True: "#8CC36C",
    False: "#B85450"
}

custom_legend_labels = {
    'None': 'Traditional',
    'Spatial': 'Spatial',
    'Full': 'Full'
}


sortedCores = ['RPU', 'RISCV']
sortedIsolations = ['Full', 'Spatial', 'None']

def keyOfIsolation(isolation):
    return ['None', 'Spatial', 'Full'].index(isolation)

# Directory path for the experiment results
results_dir = '../results/taclebench_results'

# Get the list of experiment directories
experiment_dirs = os.listdir(results_dir)

# Create ouput directory if it doesn't exist
output_directory = "./imgs"
os.makedirs(output_directory, exist_ok=True)

def extract_taclebench_data(benchmark, core):
    search_results = f"{results_dir}/{benchmark}/{benchmark}_{core}_SEARCH.txt"

    print(search_results)

    if not os.path.isfile(search_results):
        print(f"No file {search_results}")
        return (None, None)
    try:
        df = pd.read_csv(search_results, skiprows=[0])
        if len(df[df.time > 0]) == 0:
            return (None, None)
    except Exception as e:
        print(e)
        os.rename(search_results,  f"{results_dir}/{benchmark}/{benchmark}_{core}_SEARCH_corrupted.txt")
        return (None, None)

    full_df = df.copy()
    
    # Group values by bandwidth and compute some statistics on the repetions
    df = df.groupby(['bandwidth']).agg({"time":'mean', 'rep':'count', 'in_target': 'sum', 'slowdown':'mean'}).reset_index()
    
    # Extract max bandwidth slowdown
    max_bandwidth = df.bandwidth.max()
    max_bandwidth_slowdown = df[df.bandwidth == max_bandwidth].slowdown.iloc[0]

    # Filter out incomplete iterations
    df = df[(df['in_target'] == df['rep'])]

    best_bandwidth = df['bandwidth'].max()
    print(df['bandwidth'])
    best_bandwidth_slowdown = df[df['bandwidth'] == best_bandwidth].slowdown.iloc[0]

    full_df = full_df[(full_df.bandwidth == max_bandwidth) | (full_df.bandwidth == best_bandwidth)][['bandwidth', 'slowdown']]
    full_df['benchmark'] = benchmark
    full_df['core'] = core
    full_df['experiment'] = full_df.apply(lambda row: 'Unconstrained' if row.bandwidth == max_bandwidth else 'Constrained', axis=1)

    return (full_df, [benchmark, core, max_bandwidth_slowdown, best_bandwidth_slowdown, best_bandwidth])

taclebench_df, stats = zip(*[(a, b) for core in ['RPU', 'RISCV'] for a, b in [extract_taclebench_data(benchmark, core) for benchmark in experiment_dirs] if (not a is None) and (not b is None)])
taclebench_df = pd.concat(taclebench_df)

taclebench_stats = pd.DataFrame(data=stats, columns=['benchmark', 'core', 'unconstrained_slowdown', 'contrained_slowdown', 'constrained_bandwidth'])

labels_size=18
ticks_size=13

def calc_sorting_and_line_data(stats):
    sorted_benchmarks = stats.sort_values(by=['unconstrained_slowdown'])['benchmark']

    line_data = sorted_benchmarks.copy().reset_index()['benchmark'].reset_index().rename(columns={'index': 'x'})
    line_data = line_data.join(stats[['benchmark', 'constrained_bandwidth']].set_index('benchmark'), on='benchmark')
    line_data.x = line_data.x.map(lambda x: x + .5)

    line_zero = line_data.loc[[0]]
    line_zero.x = line_zero.x.map(lambda x: x - 1)

    line_data = pd.concat([line_zero, line_data])

    return sorted_benchmarks, line_data

def taclebench_plot(full_res_df, stats, ax1, splitted=False, left=True, right=False, slowdown_ylim=None, max_slowdown=None, ticks_count=6):

    if not splitted:
        left = True
        right = True

    sorted_benchmarks, line_data = calc_sorting_and_line_data(stats)

    plt.sca(ax1)
    ax1.xaxis.grid(False)

    barplot1 = sns.barplot(x='benchmark', 
                y='slowdown',
                hue='experiment',
                palette=[core_color['RISCV'], disturb_color['RPU1']],
                data=full_res_df, 
                order=sorted_benchmarks,
                linewidth=1.5,
                errorbar=('ci', 100),
                capsize=0.1,
                estimator=np.mean,
                ax=ax1
    )

    plt.axhline(y=1.3, color='black', linestyle=":", label='Target max')

    xlim = ax1.get_xlim()

    # Rotate x-axis labels and add grid lines
    plt.xticks(rotation=45, fontsize=ticks_size*1.2, ha='right')
    plt.yticks(fontsize=ticks_size)
    
    max_slowdown = full_res_df.slowdown.max()

    if slowdown_ylim is None:
        slowdown_ylim = max_slowdown * 1.1

    # i = 0
    # while plt.yticks()[0][-(i - 1)] < max_slowdown:
    #     i += 1

    plt.ylim(1, slowdown_ylim)

    if splitted:
        plt.ylim(plt.yticks()[0][0], plt.yticks()[0][-1])

    if left:
        plt.ylabel("Slowdown", fontsize=labels_size)
    else:
        plt.ylabel(None)

    plt.xlabel(None)

    if splitted:
        ticks = [t for t in np.linspace(plt.ylim()[0], plt.ylim()[1], ticks_count)]
        if not 1.2 in ticks:
            ticks += [1.2]
        plt.yticks(ticks)

    ax2 = ax1.twinx()
    ax2.xaxis.grid(False)

    if splitted:
        ax1.yaxis.set_major_formatter(lambda tick, _: f"{floor(tick * 1000)/1000}x")
        if right:
            ax2.yaxis.set_major_formatter(lambda tick, _: f"{int(tick * 10) / 10} MB/s")
        else:
            ax2.yaxis.set_major_formatter(lambda tick, _: f"{int(tick)} MB/s")
    else:
        ax1.yaxis.set_major_formatter(lambda tick, _: f"{floor(tick * 1000)/1000}x")
        ax2.yaxis.set_major_formatter(lambda tick, _: f"{floor(tick *10) / 10} MB/s")


    lineplot1 = sns.lineplot(x='x', 
                y='constrained_bandwidth',
                # color='black',
                color=disturb_color['RPU1'],
                label='Regulated bandwidth level',
                data=line_data, 
                linewidth=2.5,
                ax=ax2,
                drawstyle='steps'
    )

    h1, l1 = barplot1.get_legend_handles_labels()
    h2, l2 = lineplot1.get_legend_handles_labels()


    plt.xlim(xlim)
    # plt.xlim((xlim[0] + 3, xlim[1]))
    tmp_ylim = plt.ylim()
    if splitted:
        if right:
            # plt.ylim(tmp_ylim[0], bw_line_df.bandwidth.max() * 1.1)
            plt.ylim(8, 18.5)
        else:
            plt.ylim(0, 350)
    else:
         plt.ylim(3 - .5, ceil(tmp_ylim[1]) - .5)
    # plt.ylim(3 - .5, 20 - .5)
    # plt.ylim((floor(tmp_ylim[0]), ceil(tmp_ylim[1])))
    # plt.yticks(np.arange(3, 12.5, 1.5) - .5, fontsize=ticks_size)
    plt.xticks(fontsize=ticks_size*1.3)
    # print(plt.yticks())
    # plt.ylim(plt.yticks()[0][0], plt.yticks()[0][-1])
    
    # np.linspace(ax1.get_ybound()[0], ax1.get_ybound()[1], 5)
    # ax1.set_yticks(np.linspace(ax1.get_ybound()[0], ax1.get_ybound()[1], 6))
    if splitted:
        plt.yticks(np.linspace(plt.ylim()[0], plt.ylim()[1], ticks_count))
        # plt.yticks(plt.yticks()[0] + [1.2])
        plt.yticks(fontsize=ticks_size)
    else:
        plt.yticks(np.arange(3, 12.5, 1.5) - .5, fontsize=ticks_size)

    if right:
        plt.ylabel("Bandwidth (MB/s)", fontsize=labels_size)
    else:
        plt.ylabel(None)

    plt.xlabel(None)
    # plt.xlabel("Benchmark", fontsize=labels_size)

    plt.tight_layout()
    barplot1.get_legend().remove()
    
    if right:
        lineplot1.legend(h1 + h2,
                            [l + " slowdown (x)" for l in l1] + [f"{l} (MB/s)" for l in l2],
                            # bbox_to_anchor=(0.5, 1.03),
                            bbox_to_anchor=(0.5, 1.03),
                            loc='upper center', fontsize=labels_size-2, ncol=2)
    else:
        lineplot1.get_legend().remove()


full_res_df = taclebench_df[taclebench_df.core == 'RPU']
stats = taclebench_stats[taclebench_stats.core == 'RPU']

# Plot the boxplots
sns.set_palette("pastel")
sns.set_style("whitegrid", {"grid.color": ".90"})

plt.figure(figsize=(16, 6))

ax1 = plt.gca()
taclebench_plot(full_res_df, stats, ax1, slowdown_ylim=4)

plt.savefig(os.path.join(output_directory, "taclebench_test.png"))
plt.show()

full_res_df = taclebench_df[taclebench_df.core == 'RISCV']
stats = taclebench_stats[taclebench_stats.core == 'RISCV'].copy()
mean = stats.constrained_bandwidth.mean()
stats['threshold'] = stats.apply(lambda r: r.constrained_bandwidth > mean, axis=1)

sns.set_style("whitegrid", {"grid.color": ".90"})

full_res_df = full_res_df.join(stats[['benchmark', 'threshold']].set_index('benchmark'), on='benchmark')
grouped_full_res_df = full_res_df.groupby('threshold')
grouped_stats = stats.groupby('threshold')
max_slowdown = full_res_df.slowdown.max()
slowdown_ylim = 2.4

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6), gridspec_kw={'width_ratios': [1, len(grouped_stats.get_group(False)) / len(grouped_stats.get_group(True))]})

for ax, label in [(ax1, True), (ax2, False)]:
    __full_res_df = grouped_full_res_df.get_group(label)
    __stats = grouped_stats.get_group(label)
    taclebench_plot(__full_res_df, __stats, ax, splitted=True, slowdown_ylim=max_slowdown * 1.1, ticks_count=8, left=label, right=not label)

# Save the plot in the specified directory
plt.savefig(os.path.join(output_directory, "taclebench_riscv_test.png"))
# plt.show()

