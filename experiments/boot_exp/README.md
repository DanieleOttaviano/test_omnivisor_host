# **Boot Experiments**
This folder contains a set of scripts to test the boot times of a virtual machine over local and remote processors.

Supported Board:
- [x] Zynq Ultrascale +

Supported Cores:
- [x] Cortex-a53 (APU)
- [x] Cortex-R5F (RPU)
- [x] Pico32 on FPGA (RISC-V)

**Prerequisite**
To launch these scripts you need to:
- Use RunPHI project to install and configure the Omnivisor on your board.
- Configure the specific information of your board (IP, serial, etc ...) in the script: "test_omnivisor_host/utility/board_info.sh"
- Configure the specific path of the directories (RunPHI and Jailhouse/Omnivisor) in the script: "test_omnivisor_host/utility/default_directories.sh"

***Prepare Images***
The test use a set of images with different sizes for each processor. To create these images you can use the following scripts:
```bash
./create_images_APU.sh
./create_images_RISCV.sh
./create_images_RPU.sh
```

Now that the images are ready you need to copy them in the board directory. You can use the runPHI script:
```bash
./scripts/remote/load_install_dir_to_remote.sh 
```


**Launch Tests**
- launch the script start_boot_exp.sh to run the experiments:
    This script launch the VM Boot test on a ZCU board on the specified processor:
    > [-r <repetitions>]
    > [-c <core> (APU, RPU, RISCV)]
    > [-s save the results on the host machine]
    > [-h help]

example:
```bash
./start_boot_exp.sh -r 100 -c APU -s
./start_boot_exp.sh -r 100 -c RPU -s
./start_boot_exp.sh -r 100 -c RISCV -s
```

*Results*
The raw results are saved in the directory "test_omnnivisor_host/results/boot_results". 
To visualize the results launch the scripts in the "test_omnnivisor_host/notebooks/Omnivisor_test_plots.ipynb".