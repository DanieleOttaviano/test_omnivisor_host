#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

# Clean Restart Board
echo "Clean Restart Board..."
bash ${UTILITY_DIR}/board_restart.sh

# Launch Tests
echo "**************** Launch Tests ****************"
./start_filestate_taclebench.sh -c RPU -r 30
./start_filestate_taclebench.sh -c RPU -r 30 -d 
./start_filestate_taclebench.sh -c FPGA -r 30 
./start_filestate_taclebench.sh -c FPGA -r 30 -d 