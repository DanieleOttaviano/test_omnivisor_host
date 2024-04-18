# **Test Omnivisor Host**

This repository contains scripts and materials to replicate the experiments on Omnivisor (https://github.com/DanieleOttaviano/jailhouse).

## Overview

### Supported Hypervisor:
- [x] Jailhouse

### Supported Board:
- [x] Zynq Ultrascale +

### Supported Cores:
- [x] Cortex-a53 (APU)
- [x] Cortex-R5F (RPU)
- [x] Pico32 on FPGA (RISC-V)

## Prerequisites

Before running these scripts, ensure the following prerequisites are met:

1. Install and configure the Omnivisor on your board using the RunPHI project available at: [RunPHI-project](https://dessert.unina.it:8088/ldesi/runphi/-/tree/main/scripts).
2. Have Test_Omnivisor_Guest installed on the board filesystem, accessible at: [Test_Omnivisor_Guest](https://github.com/DanieleOttaviano/test_omnivisor_guest).
3. Configure board-specific information (IP, serial, etc.) in the script: `test_omnivisor_host/utility/board_info.sh`.
4. Configure the paths of the directories (RunPHI and Jailhouse/Omnivisor) in the script: `test_omnivisor_host/utility/default_directories.sh`.

## Running Experiments

The following experiments are available:

- **Boot Times**: Measure boot times of different configurations.
- **Isolation Experiments**: Evaluate isolation properties of Omnivisor.
- **Taclebench Experiments**: Benchmarking using Taclebench.

Refer to the README in each directory under "experiments/" for detailed instructions on how to run these experiments.

## Results

Raw results are saved in the directory `test_omnnivisor_host/results`. Visualize the results using the provided notebook: `test_omnnivisor_host/notebooks/Omnivisor_test_plots.ipynb`.
