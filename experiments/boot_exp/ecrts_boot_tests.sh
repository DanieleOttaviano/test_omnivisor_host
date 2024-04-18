#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

# Clean Restart Board
echo "Clean Restart Board..."
bash ${UTILITY_DIR}/board_restart.sh

# Create and Load Images 
echo "**************** Create and Load Images ****************"
echo "Creating Images..."
./create_Images_APU.sh
./create_Images_RISCV.sh
./create_Images_RPU.sh
echo "Loading Images..."
bash ${RUNPHI_SCRIPTS_DIR}/remote/load_install_dir_to_remote.sh 

# Launch Tests
echo "**************** Launch Tests ****************"
./start_boot_exp.sh -r 100 -c APU -s
./start_boot_exp.sh -r 100 -c RPU -s
./start_boot_exp.sh -r 100 -c RISCV -s