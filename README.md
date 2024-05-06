# **Test Omnivisor Host**

This repository contains scripts and materials to replicate the results provided in the paper "The Omnivisor: A real-time static partitioning hypervisor extension for heterogeneous core virtualization over MPSoCs" accepted to ECRTS 2024.

## Important Repositories
[Omnivisor](https://github.com/DanieleOttaviano/jailhouse): The repository containing the features included in the Jailhouse hypervisor to manage remote cores using the Omnivisor model.

[Test_Omnivisor_Guest](https://github.com/DanieleOttaviano/test_omnivisor_guest): The repository containing the scripts that run directly on board (guest).

## Overview

### Supported Hypervisor:
- [x] Jailhouse

### Supported Board:
- [x] Zynq Ultrascale +

### Supported Cores:
- [x] Cortex-a53 (APU)
- [x] Cortex-R5F (RPU)
- [x] Pico32 on FPGA (RISC-V)


## Experiments Description
The tests aims to address the following questions:
1. Is the boot time of a VM on a remote core comparable to that on main cores?
2. What degree of spatio-temporal isolation does the Omnivisor guarantee for remote VMs?
3. Can the Ominvisor be a turnkey solution to achieve controlled degradation?

### Experiments Organization
To address the questions we provide three experiments the results of which are shown in the Fig.4, Fig.6 and Fig.7 in the paper.
1. **Boot Times**: Measure boot times of different configurations.
2. **Isolation Experiments**: Evaluate isolation properties of Omnivisor.
3. **Taclebench Experiments**: Benchmarking using Taclebench.

### Detailed Descriptions
1. **Boot Times**: 
The experiments measure the time needed to run a simple bare-metal application of different sized as a VM on different processing cores, specifically on Cotex-a53(APU), Cortex-R5F(RPU), and Pico32 (RISC-V soft-core). 
To do it, first we compile 10 images of different sizes (1MB, 10MB, 20MB, 30MB, 40MB, 50MB, 60MB, 70MB, 80MB, 90MB) for each processor (APU, RPU, RISC-V) using the compiling tools we have integrated in the Omnivisor repository.
Then, we use the Jailhouse command line interface (create, load and start) and the Omnivisor extension functionalities to launch these VM Images on the cores, and we leverage the global timers in the platform to capture the boot times. Each VM Image is launched 100 times in order to have a statistically significant number of experiments.

2. **Isolation Experiments**: 
The experiments measure the execution time of a simple periodic task implemented in a VM that runs on remote cores (RPU and RISC-V). We consider various scenarios where, while the VM under test is running, a disturbance code is executed on different cores (APU, RPU1, FPGA). To do so, first we compile the VM under test for RPU and RISC-V using the compiling tools we have integrated in the Omnivisor repository. Then, we start the VM under test on one of the core (RPU, RISC-V) and after few seconds we start the disturbance application on one of the other cores (APU, RPU1, FPGA). After repeting the experiments for each combination of core under test and disturbance core, we recompile the Omnivisor adding the spatial isolation features (XMPUs) and we repete the tests. Finally, we enabled the Omnivisor with both temporal (QoS) and spatial (XMPUs) isolation features and repete again the tests.

3. **Taclebench Experiments**: 
The experiments measure the execution time of the entire Taclebench suite executed on both the remote cores (RPU and RISC-V) while changing the QoS configuration using the Omnivisor interface to reach controlled degradation.
We first compile the Taclebench suite for both the cores using the compiling tools integrated in the Omnivisor repository. For the RISC-V core we removed the test that requires a floating point extension since the PICO32 RISC-V core used doesn't have it.
After that, we launch the entire suite on the cores under test (RPU, RISC-V) both in isolation and when the other cores (APU, RPU1, FPGA) cause interference running membomb applications. We repete the tests 30 times to produce statistically significant results. Then we run a binary search algorythm that modify the memory bandwidth assigned to the disturbance cores to reach a controlled slowdown on the application of the 20% compared to the calculated baseline.


### Experiments Results
The results claims are the following:

1. **Boot Times**: We demonstrate that booting a VM on a remote core using Omnivisor is comparable in time to booting a VM via Jailhouse on a main core.

2. **Isolation Experiments**: We first demonstrate that withouth the Omnivisor protection mechanism enabled the disturbance cores are able to crash the VM under test in most cases. Then, we demonstrate that if only the spatial isolation is provided, even if the VM doesn't crash anymore, the disturbance core are able to delay the execution time of the VM under test. Finally, we demonstrate that using the Omnivisor complete implementation of spatial and temporal isolation the VM under test presents only a negligible delay of the execution time.

3. **Taclebench Experiments**:  
The objective of this experiments is twofold: first, to demonstrate how the Omnivisor can induce controlled degradation in the execution time of a VM running on remote cores, and second, to elucidate how the Omnivisor streamlines the parameter tuning process for achieving an acceptable performance degradation level.

## Running Experiments

The following scripts can be used to produce the results: 

```bash
./experiments/boot_exp/ecrts_boot_tests.sh
```

```bash
./experiments/isolation_exp/ecrts_isolation_tests.sh
```

```bash
./experiments/taclebench_exp/ecrts_taclebench_tests.sh
```

Refer to the README in each directory under "experiments/*" for detailed instructions on how to run these experiments step-by-step.

## Results

Results can be visualized in the provided notebook: `test_omnnivisor_host/notebooks/Omnivisor_test_plots.ipynb`.
