To run the boot experiments: 

1) Create the images for all the cores: 
    -launch create_images_APU.sh
    -launch create_images_RISCV.sh
    -launch create_images_RPU.sh

2) Launch the experiments
    - launch start_boot_exp.sh
        This script launch the VM Boot test on a ZCU board on the specified processor:\r\n \
            [-r <repetitions>]\r\n \
            [-c <core> (APU, RPU, RISCV)]\r\n \
            [-s save the results on the host machine]\r\n \
            [-p print the results in and save in imgs directory]\r\n \
            [-h help]

    - Repete the test for each core
    
3) Visualize the results
    - launch the scripts in the Isolation.ipynb notebook to visualize the results.