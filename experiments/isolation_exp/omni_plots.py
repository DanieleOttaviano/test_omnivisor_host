import os
import pandas as pd
import numpy as np

###
#   Reading utilities
###

# Directory containing the tests results
results_directory = '/home/daniele/projects/runphi/tests/omnivisor/results/isolation_results'

# Get all the txt files in the directory
txt_files = [file for file in os.listdir(results_directory) if file.endswith(".txt")]

# Empty array to collect the results from the txt files
files_data = []

# Iterate over the txt files
for file in txt_files:
    # Extract the core and disturb from the file name
    core, disturb = '.'.join(file.split('.')[:-1]).split("_")[:2]
    # print(core)
    isolation = ('Full' if 'tmp' in file else 'Spatial') if 'spt' in file else 'None'

    file_path = os.path.join(results_directory, file)
    with open(file_path, "r") as f:
        data = [int(line.strip()) / 1000 for line in f][:100]
    files_data += [(time, core, isolation, disturb, value if value > 0 else None) for value, time in zip(data, np.arange(0, 20, .2))]


# Initialize a DataFrame of all the data
files_df = pd.DataFrame(files_data, columns=['Time', 'Core', 'Isolation', 'Disturb', 'Value'])

###
#   Sorting utilities
###

sortedCores = ['RPU', 'RISCV']
sortedIsolations = ['Full', 'Spatial', 'None']

def keyOfIsolation(isolation):
    return ['None', 'Spatial', 'Full'].index(isolation)

###
#   Plot style elements
###

plots_fig_size = (10, 6)
labels_fontsize = 23
ticks_fontsize = 18
plot_linewidts = 2.5

lines_styles = dict(
    [
        ('RPU', dict ([
            ('None', dict([
                ('Color', '#F9665E'), #red
                ('Style', '-')
            ])),
            ('Spatial', dict([
                ('Color', '#F9665E'), #red
                ('Style', '--')
            ])),
            ('Full', dict([
                ('Color', '#F9665E'), #red
                ('Style', (0, (1, 3)))
            ]))
        ])),
        ('RISCV', dict ([
            ('None', dict([
                ('Color', '#799FCB'), #blue
                ('Style', '-')
            ])),
            ('Spatial', dict([
                ('Color', '#799FCB'), #blue,
                ('Style', '--')
            ])),
            ('Full', dict([
                ('Color', '#799FCB'), #blue,
                ('Style', (2, (1, 3)))
            ]))
        ]))
    ]
)

###
#   Output tools
###

# Create the imgs directory if it doesn't exist
output_directory = "/home/daniele/projects/runphi/tests/omnivisor/imgs"
os.makedirs(output_directory, exist_ok=True)
