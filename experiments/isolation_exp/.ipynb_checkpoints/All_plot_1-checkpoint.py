import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import sys
import os
import numpy as np

from omni_plots import *

# Get output file name as first argument
output_filename = "RISCV_RPU_ALL" #sys.argv[1]

disturbs_data = [
    {
        'name': 'APU',
        'color': '#A88EB3',
        'x_pos': 4
    },
    {
        'name': 'RPU-1',
        'color': '#E3D346',
        'x_pos': 8
    },
    {
        'name': 'FPGA 1',
        'color': '#8BB3B5',
        'x_pos': 12
    },
    {
        'name': 'FPGA 2',
        'color': '#ADCECF',
        'x_pos': 16
    },
]

plt.figure(figsize=plots_fig_size)
# sns.set_style("whitegrid")
sns.set_style("whitegrid", {"grid.color": ".95"})

ax = plt.gca()

for core in sortedCores:
    for isolation in sortedIsolations[:2]:
        line_style = lines_styles[core][isolation]
        ax = sns.lineplot(
                x='Time', y='Value',
                data=files_df[(files_df.Disturb == 'ALL') & (files_df.Core == core) & (files_df.Isolation == isolation)],
                label=f'{core} {isolation} isolation',
                linewidth=plot_linewidts,
                color=line_style['Color'],
                linestyle = line_style['Style'],
                alpha=0.9,
                ax=ax)

# ax.xaxes.grid(False)
ax.yaxis.grid(True)

plt.xticks(np.arange(0, 22, 2), fontsize=ticks_fontsize)
plt.yticks(np.arange(0, 221, 20),fontsize=ticks_fontsize)

for disturb_data in disturbs_data:
    plt.text(disturb_data['x_pos'], 230, disturb_data['name'], fontsize=labels_fontsize, weight='bold', ha='center', va='center', color=disturb_data['color'])
    plt.axvline(x=disturb_data['x_pos'], linestyle='-', linewidth=1, alpha=0.4, color='black')

plt.xlabel("Test time(s)", fontsize=labels_fontsize)
plt.ylabel("Execution Time(ms)", fontsize=labels_fontsize)

plt.legend(
                    # bbox_to_anchor=(0.5, 1.07),
                    loc='lower center', fontsize=ticks_fontsize, ncol=2)

# Save the plot in the specified directory
plt.savefig(os.path.join(output_directory, (output_filename + ".png")))

print("Plot saved in " + output_directory + "/" + output_filename + ".png")
