# **Isolation Experiments**

This folder contains a set of scripts designed to evaluate the isolation capabilities of the Omnivisor in comparison with a Legacy hypervisor.

### Single Script Test

To replicate the ECRTS results, execute the following script:

```bash
./ecrts_isolation_tests.sh
```

To replicate the test step by step continue reading.

### Prepare Images
To compile the VM under test that will be used in the tests, use the following scripts: 
```bash
./create_VMs_under_test.sh
```
Once the images are ready, copy them to the board directory using the script:

```bash
../../../../scripts/remote/load_install_dir_to_remote.sh
```

### Launching Single Experiment

To initiate a single isolation experiment, use the following script:

```bash
./start_isolation_exp.sh -c <core> -d <disturb> [-S] [-T] [-s]
```

This script starts the isolation test on the selected processor with the chosen disturbance sources:

- `-c <core under isolation test>` (Options: RPU, RISCV)
- `-d <source of disturbance>` (Options: APU, RPU1, FPGA, ALL)
- `-S` Apply spatial isolation (enable XMPUs)
- `-T` Apply temporal isolation (enable QoS + Memguard)
- `-s` Save the results
- `-h` Help

Example:

```bash
./start_isolation_exp.sh -c RPU -d FPGA -S -T -s
```

The following sequence of scripts replicate exactly the results of the paper:
```bash
#Legacy Hypervisor 
## Core under test:  RPU
./start_isolation_exp.sh -c RPU -d RPU1 -s
./start_isolation_exp.sh -c RPU -d APU -s
./start_isolation_exp.sh -c RPU -d FPGA -s

## Core under test: RISCV
./start_isolation_exp.sh -c RISCV -d RPU1 -s
./start_isolation_exp.sh -c RISCV -d APU -s
./start_isolation_exp.sh -c RISCV -d FPGA -s

# Omnivisor Spatial Isolation
## Core under test: RPU
./start_isolation_exp.sh -c RPU -d RPU1 -S  -s
./start_isolation_exp.sh -c RPU -d APU -S  -s
./start_isolation_exp.sh -c RPU -d FPGA -S  -s
./start_isolation_exp.sh -c RPU -d ALL -S  -s

## Core under test: RISCV
./start_isolation_exp.sh -c RISCV -d RPU1 -S -s
./start_isolation_exp.sh -c RISCV -d APU -S -s
./start_isolation_exp.sh -c RISCV -d FPGA -S -s
./start_isolation_exp.sh -c RISCV -d ALL -S -s

# Full Omnivisor: Spatial and Temporal Isolation
## Core under test: RPU
./start_isolation_exp.sh -c RPU -d RPU1 -S -T -s
./start_isolation_exp.sh -c RPU -d APU -S -T -s
./start_isolation_exp.sh -c RPU -d FPGA -S -T -s
./start_isolation_exp.sh -c RPU -d ALL -S -T -s

## Core under test: RISCV
./start_isolation_exp.sh -c RISCV -d RPU1 -S -T -s
./start_isolation_exp.sh -c RISCV -d APU -S -T -s
./start_isolation_exp.sh -c RISCV -d FPGA -S -T -s
./start_isolation_exp.sh -c RISCV -d ALL -S -T -s
```

**Results**

The raw results are stored in the directory `test_omnnivisor_host/results/isolation_results`. Visualize the results using the provided notebook: `test_omnnivisor_host/notebooks/Omnivisor_test_plots.ipynb`.
