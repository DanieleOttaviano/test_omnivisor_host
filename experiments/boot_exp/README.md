# **Boot Experiments**

This folder contains a set of scripts to test the boot times of a virtual machine over local and remote processors.

### Test Fast Script

To replicate the results for ECRTS, execute the following script:

```bash
./ecrts_boot_tests.sh
```

### Prepare Images

The test uses a set of images with different sizes for each processor. To create these images, you can use the following scripts:

```bash
./create_Images_APU.sh
./create_Images_RISCV.sh
./create_Images_RPU.sh
```

Once the images are ready, you need to copy them to the board directory. You can use the RunPHI script:

```bash
./scripts/remote/load_install_dir_to_remote.sh 
```

**Launching Tests**

Launch the script \`start_boot_exp.sh\` to run the experiments. The script initiates the VM Boot test on a ZCU board on the specified processor:

- \`-r <repetitions>\`
- \`-c <core>\` (Options: APU, RPU, RISCV)
- \`-s\` Save the results on the host machine
- \`-h\` Help

Example:

```bash
./start_boot_exp.sh -r 100 -c APU -s
./start_boot_exp.sh -r 100 -c RPU -s
./start_boot_exp.sh -r 100 -c RISCV -s
```

**Results**

The raw results are saved in the directory \`test_omnnivisor_host/results/boot_results\`. Visualize the results using the provided notebook: \`test_omnnivisor_host/notebooks/Omnivisor_test_plots.ipynb\`.
