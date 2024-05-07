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


# Directory containing the tests results
results_directory = '../results/isolation_results'

# Get all the txt files in the directory
txt_files = [file for file in os.listdir(results_directory) if file.endswith(".txt")]

# Empty array to collect the results from the txt files
files_data = []

isoexp_isolation_labels = {
    'spt_tmp': 'Full',
    'spt': 'Spatial',
    '': 'None'
}

def read_isolation_results_file(filename):

    # Get complete file path and read data from result file
    file_path = os.path.join(results_directory, filename)
    with open(file_path, "r") as f:
        data = [int(line.strip()) / 1000 for line in f][:100]
    
    # Extract the core, disturb and isolation from the file name
    segments = '.'.join(filename.split('.')[:-1]).split("_")
    core, disturb = segments[:2]
    isolation = isoexp_isolation_labels['_'.join(segments[2:])]

    return [(time, core, isolation, disturb, value if value > 0 else None) for value, time in zip(data, np.arange(0, 20, .2))]

# pp([read_isolation_results_file(file) for file in txt_files])
isolation_raw_data = [line for file in txt_files for line in read_isolation_results_file(file) ]

# Iterate over the txt files
for file in txt_files:

    # Get complete file path and read data from result file
    file_path = os.path.join(results_directory, file)
    with open(file_path, "r") as f:
        data = [int(line.strip()) / 1000 for line in f][:100]
    
    # Extract the core, disturb and isolation from the file name
    segments = '.'.join(file.split('.')[:-1]).split("_")
    core, disturb = segments[:2]
    isolation = isoexp_isolation_labels['_'.join(segments[2:])]

    tmp = [(time, core, isolation, disturb, value if value > 0 else None) for value, time in zip(data, np.arange(0, 20, .2))]
    tmp_1 = read_isolation_results_file(file)

    # pp(tmp)
    # pp(tmp_1)
    # pp([a for a in zip(tmp, tmp_1)])

    files_data += [(time, core, isolation, disturb, value if value > 0 else None) for value, time in zip(data, np.arange(0, 20, .2))]


isolation_df = pd.DataFrame(isolation_raw_data, columns=['Time', 'Core', 'Isolation', 'Disturb', 'Value'])

# Initialize a DataFrame of all the data
files_df = pd.DataFrame(files_data, columns=['Time', 'Core', 'Isolation', 'Disturb', 'Value'])

# Create the imgs directory if it doesn't exist
output_directory = "./imgs"
os.makedirs(output_directory, exist_ok=True)

isolation_df_all = isolation_df.copy()

isolation_df_individual = files_df.copy()
isolation_df_individual = pd.DataFrame(isolation_df_individual[(isolation_df_individual.Disturb != 'NONE') & (isolation_df_individual.Disturb != 'ALL')])

# Baselines
bl = dict(
            isolation_df_individual[(isolation_df_individual.Value > 0)]
                .groupby(['Disturb', 'Core'])
                .min()
                .reset_index()
                .apply(lambda r: ((r.Core, r.Disturb), r.Value), axis = 1)
                .array
        )

def to_slowdown(row):
    # if not np.isnan(row.Value):
    row.Value /= bl[(row.Core, row.Disturb)]
    return row
    
isolation_df_individual = isolation_df_individual.apply(to_slowdown, axis = 1)

plt.figure(figsize=plots_fig_size_alt)
sns.set_style("whitegrid", {"grid.color": ".95"})
ax = plt.gca()

for core in sortedCores:
    for isolation in sortedIsolations[:2]:
        ax = sns.lineplot(
                x='Time', y='Value',
                data=isolation_df_all[(isolation_df_all.Disturb == 'ALL') & (isolation_df_all.Core == core) & (isolation_df_all.Isolation == isolation)],
                label=f'{core} {isolation} isolation',
                linewidth=plot_linewidts,
                color=core_color[core],
                linestyle =isolation_style[isolation][core],
                alpha=0.9,
                ax=ax)

ax.yaxis.grid(True)

plt.xticks(np.arange(0, 22, 2), fontsize=ticks_fontsize)
plt.yticks(np.arange(0, 221, 20),fontsize=ticks_fontsize)

for i, disturb in enumerate(['APU', 'RPU1', 'FPGA1', 'FPGA2']):
    plt.text(4 * (i + 1), 230, disturb, fontsize=labels_fontsize*.92, weight='bold', ha='center', va='center', color=disturb_color[disturb])
    plt.axvline(x=4 * (i + 1), linestyle='-', linewidth=1, alpha=0.4, color='black')

plt.xlabel("Test time(s)", fontsize=labels_fontsize)
plt.ylabel("Execution Time(ms)", fontsize=labels_fontsize)

plt.legend(
    # bbox_to_anchor=(0.5, 1.07),
    loc='lower center', fontsize=ticks_fontsize * .73, ncol=2)

# fig = plt.figure()
plt.tight_layout()

# Save the plot in the specified directory
plt.savefig(os.path.join(output_directory, ("RISCV_RPU_ALL.png")))

sns.set_style("whitegrid", {"grid.color": ".85"})

for disturb, disturb_df in isolation_df_individual.groupby('Disturb'):

    # Create a line plot using seaborn
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=plots_fig_size if disturb != 'FPGA' else plots_fig_size_alt, gridspec_kw={'height_ratios': [5, 2]})
    plt.sca(ax1)

    max_slowdown = disturb_df[(disturb_df.Time > 1.9) & (disturb_df.Time < 2.5) & (disturb_df.Isolation != 'Spatial')].Value.max()
    

    axins = ax1.inset_axes(
            [0.35, 0.51, 0.63, 0.42],
            xlim=(1.5, 2.5), ylim=(.99, max_slowdown + .01),
            yticks=[1, floor((max_slowdown + .01) * 100)/ 100]
        )

    ax1.indicate_inset_zoom(axins, edgecolor="black")
    ax1.axvline(x=2, linestyle='-', linewidth=2, alpha=0.4, color='black')
    axins.axvline(x=2, linestyle='-', linewidth=2, alpha=0.4, color='black')
    ax2.axis('on')

    for core, disturb_core_df in disturb_df.groupby('Core'):
        i = sortedCores.index(core)

        core_base_y = i * .8

        if (disturb != 'FPGA'):
            # ax2.text(-2.8, core_base_y + .5, 'Hyp', va='center', ha='center', color=core_color[core], rotation='horizontal', fontsize=14)
            ax2.text(-2.85, core_base_y + .5 * .2 + .05, 'Omn', va='center', ha='center', color=core_color[core], rotation='horizontal', fontsize=18)
            ax2.text(-2.35, core_base_y + .5 * .2 + .05, '{', va='center', ha='center', color=core_color[core], rotation='horizontal', fontsize=26)
            ax2.text(-3.4, core_base_y + .2 + .05 + .05/3, core, va='center', ha='center', color=core_color[core], rotation='vertical', fontsize=18)
        
        for isolation, line_df in disturb_core_df.groupby('Isolation'):
            k = sortedIsolations.index(isolation)

            for __ax in [ax1, axins]:
                sns.lineplot(data=line_df, x='Time', y='Value', linewidth=plot_linewidts, alpha=0.9, color=core_color[core], linestyle = isolation_style[isolation][core], ax=__ax)

            line_y = core_base_y + k * .2 + (0 if k < 2 else .05) + .05
            if (disturb != 'FPGA'):
                ax2.axhline(y = line_y, xmin = -.12, xmax = -.01, color=core_color[core], linestyle=isolation_style[isolation][core], linewidth=2.5, clip_on=False)

            for k1, v1 in enumerate(line_df.Value):
                ax2.add_patch(Rectangle((k1 * .2, line_y - .05), .2, 0.1, color=activation_colors[not np.isnan(v1)], alpha=0.8))
            
            if (disturb != 'FPGA'):
                ax2.text(-1.3, line_y, custom_legend_labels[isolation], va='center', ha='right', color=core_color[core], fontsize=14)

    plt.text(2, 2.1, disturb, fontsize=labels_fontsize, weight='bold', ha='center', va='center', color=disturb_color[disturb])
    
    plt.xlabel("Test time(s)", fontsize=labels_fontsize)
    if (disturb != 'FPGA'):
        plt.ylabel("Slowdown", fontsize=labels_fontsize)
    else:
        plt.ylabel("")
    plt.xticks(np.arange(0, 22, 2), fontsize=ticks_fontsize)
    plt.yticks(fontsize=ticks_fontsize)
    plt.ylim(.95, 2.05)
    plt.xlim(0, 10)

    axins.set_ylabel('')
    axins.set_xlabel('')

    plt.sca(ax2)

    ax2.set_xlim(0, 10)
    ax2.set_ylim(0, 1.35)
    plt.xticks(np.arange(0, 12, 2), fontsize=13)
    
    plt.yticks([])
    plt.xticks([])
    if disturb != 'FPGA':
        plt.subplots_adjust(left=0.26, right=.97, hspace=.3, bottom=.05, top=.95)
    else:
        plt.subplots_adjust(left=0.07, right=.97, hspace=.3, bottom=.05, top=.95)

    # plt.sca(axins)
    axins.tick_params(labelsize=ticks_fontsize*.8)

    plt.savefig(os.path.join(output_directory, f"{disturb}_plot.png"))
    

