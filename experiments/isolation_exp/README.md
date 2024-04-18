# **Isolation Experiments**

This folder contains a set of scripts designed to evaluate the isolation capabilities of the Omnivisor in comparison with a Legacy hypervisor.

### Test Fast Script

To replicate the ECRTS results, execute the following script:

```bash
./ecrts_isolation_tests.sh
```

To replicate the test step by step continue reading.


### Launching Single Experiment

To initiate a single isolation experiment, use the following script:

```bash
./start_isolation_exp.sh -c <core> -d <disturb> [-S] [-T] [-s]
```

This script starts the isolation test on the selected processor with the chosen disturbance sources:

- \`-c <core under isolation test>\` (Options: RPU, RISCV)
- \`-d <source of disturbance>\` (Options: APU, RPU1, FPGA, ALL)
- \`-S\` Apply spatial isolation (enable XMPUs)
- \`-T\` Apply temporal isolation (enable QoS + Memguard)
- \`-s\` Save the results
- \`-h\` Help

Example:

```bash
./start_isolation_exp.sh -c RPU -d FPGA -S -T -s
```

**Results**

The raw results are stored in the directory \`test_omnnivisor_host/results/isolation_results\`. Visualize the results using the provided notebook: \`test_omnnivisor_host/notebooks/Omnivisor_test_plots.ipynb\`.
