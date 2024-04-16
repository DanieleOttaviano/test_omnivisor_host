#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

# Clean Restart Board
echo "Clean Restart Board..."
bash ${UTILITY_DIR}/board_restart.sh

#Legacy Hypervisor 
echo "**************** Legacy Hypervisor ****************"
## Core under test:  RPU
./start_isolation_exp.sh -c RPU -d RPU1 -s
./start_isolation_exp.sh -c RPU -d APU -s
./start_isolation_exp.sh -c RPU -d FPGA -s

## Core under test: RISCV
./start_isolation_exp.sh -c RISCV -d RPU1 -s
./start_isolation_exp.sh -c RISCV -d APU -s
./start_isolation_exp.sh -c RISCV -d FPGA -s

# Omnivisor Spatial Isolation
echo "**************** Omnivisor Spatial Isolation ****************"
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
echo "**************** Full Omnivisor: Spatial and Temporal Isolation ****************"
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

echo "**************** Isolation Experiments Done ****************"