# **Taclebench Experiments**

This directory contains a hierarchy of scripts to reproduce the taclebench tests shown in the paper.

## Single script test

To replicate the results for ECRTS with a single script, execute the following script:

```bash
./ecrts_taclebench_tests.sh -b
```

## Manual executions
### Prepare images

The test uses a set of images with different sizes for each processor. To create these images, use the following scripts:

```bash
./create_tacle_bin.sh
```

Once the images are ready, copy them to the board directory using the script:

```bash
../../../../scripts/remote/load_install_dir_to_remote.sh
```

### Launching Test

Launch the script `start_filestate_taclebench.sh` to run the experiments.

It has to be run twice for each remote core (RPU, RISCV);
the first execution with no disturb, to have a baseline for the binary search, the second time with disturb and a target slowdown to be reached through binary search.



The options to tweek to achive the results as in the paper are the following:
- `-c <core>` (Options: RPU, RISCV)
- `-S <target_slowdown>` execute the test as binary search to achieve given slowdown
- `-r <repetitions>` number of execution for each iteration (10 each test for binary search, 1 otherwise)
- `-s` save the results locally

Example:

```bash
./start_filestate_taclebench.sh -c RPU -r 30  -s
./start_filestate_taclebench.sh -c RPU -r 30 -s -S 1.2
```

## Results

The raw results are saved in `../../results/taclebench_results/`. To plot the results use the provided notebook `../../notebooks/Omnivisor_test_plots.ipynb`