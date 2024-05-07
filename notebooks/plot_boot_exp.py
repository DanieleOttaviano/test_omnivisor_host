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

frequency = 100000
limit = 4294967295  # int of 0xFFFFFFFF

# TODO [POROC]
##  
## [🗸] Cambiare y testi
## [🗸] Legende
## [🗸] Spazio bianco

# Create output directory if it doesn't exist
output_directory = "./imgs"
results_directory = '../results/boot_results'
os.makedirs(output_directory, exist_ok=True)

# Read the input files
stages = ['init_time', 'create_time', 'load_time', 'boot_time']
# pstages = ['Init', 'Create', 'Load', 'Boot']
# labels = [None, 'Create', 'Create + Load', 'Create + Load + Boot']
pstages = ['Init', 'Create', 'Create + Load', 'Create + Load + Start']
dataframes = {}

# Plot with Seaborn
plt.figure(figsize=(27, 6))

for i, core in enumerate(['APU', 'RPU', 'RISCV']):
    core_dataframes = {}
    # Retrieve datas from files
    for j, stage in enumerate(stages):
        file_path = os.path.join(results_directory, f'boot_{core.upper()}/{stage}.txt')
        core_dataframes[pstages[j]] = pd.read_csv(file_path, header=None, delimiter=" ", names=['Time', 'Image Size'])
    
    # Calculate the time differences
    for j, stage in enumerate(pstages[1:]):
        core_dataframes[stage]['Time'] = [(end - start) / frequency if end > start else (end + (limit - start)) / frequency
                                          for start, end in zip(core_dataframes['Init']['Time'], core_dataframes[stage]['Time'])]
    
    # Concatenate dataframes
    pd_keys=pstages[1:]
    pd_keys.reverse()
    core_df = pd.concat(core_dataframes, keys=pd_keys)
    core_df.index.names = ['Stage', 'Index']

    dataframes[core] = core_df
    
    # Calculate the maximum and minimum for each Image Size
    max_core_df = core_df.groupby('Image Size')['Time'].max().reset_index()
    
    # Save dataframe to file
    with open(os.path.join(results_directory, f'boot_{core}/{core}_boot_times.txt'), 'w') as file:
        pd.set_option('display.max_rows', None)  # Set the option to display all rows
        file.write(str(core_df))
    
    # Save max values to file
    with open(os.path.join(results_directory, f'boot_{core}/Max_{core}_boot_times.txt'), 'w') as file:
        pd.set_option('display.max_rows', None)  # Set the option to display all rows
        file.write(str(max_core_df))

    core_df['Image Size'] += 100 * i
    max_core_df['Image Size'] += 100 * i

    # sns.set_style("whitegrid")
    sns.set_style("whitegrid", {"grid.color": ".85"})
    sns.scatterplot(data=max_core_df, x='Image Size', y='Time', color='red',#activation_colors[False],
                     marker='_', s=2000, label='Max' if i == 0 else None)
    sns.lineplot(data=core_df, x='Image Size', y='Time', hue='Stage', linewidth=5, style='Stage',
                    palette='Set2', #[activation_colors[True] , disturb_color['RPU1'], disturb_color['FPGA2']],
                 markers=True, dashes=False, markersize=20, errorbar=('ci', 100),
                 legend=None if i > 0 else 'auto')

    if i > 0:
        plt.axvline(x=100 * i - 5, linestyle='-', linewidth=1, alpha=1, color='black')
    plt.text(100 * i + 45, 530, f"Boot Time {core} ({'Hypervisor' if core == 'APU' else 'Omnivisor'})", ha='center', va='center', fontsize=28)

def create_xticks(i):
    xticks = [j for j in range(0, i * 100, 10)]
    xlabels = []
    for j in range(i):
        xticks[j*10] = 1 + j * 100
        xlabels += xticks[:10]
    return xticks, xlabels

# Adjust plot details
plt.xlim(-5, 100*3 -5)
plt.ylim(0, 500)

xticks, xlabels = create_xticks(3)

plt.xticks(xticks, labels=xlabels, fontsize=26)
plt.yticks(fontsize=26)
plt.ylabel("Time (ms)", fontsize=28)
plt.xlabel("VM Image Size (MB)", fontsize=28)
# plt.title(f"Boot Times {core}", fontsize=28)
plt.legend(loc='upper left', fontsize=22)
plt.tight_layout()
    
# Save the image
plt.savefig(os.path.join(output_directory, f"boot_times_ALL.png"))

# plt.show()