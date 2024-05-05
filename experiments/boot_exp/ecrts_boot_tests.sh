#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

# Clean Restart Board
echo "Clean Restart Board..."
bash ${UTILITY_DIR}/board_restart.sh

# Launch Tests
echo "**************** Launch Tests ****************"
./start_boot_exp.sh -r 100 -c APU -s
./start_boot_exp.sh -r 100 -c RPU -s
./start_boot_exp.sh -r 100 -c RISCV -s