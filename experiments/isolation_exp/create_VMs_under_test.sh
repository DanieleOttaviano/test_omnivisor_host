#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"
SRC_RPU_DIR="${JAILHOUSE_DIR}/inmates/demos/armr5/src"
SRC_RPU_BAREMETAL_DIR="${JAILHOUSE_DIR}/inmates/demos/armr5/src_baremetal"
SRC_RISCV_DIR="${JAILHOUSE_DIR}/inmates/demos/riscv/src"
SRC_RISCV_BOOT_DIR="${JAILHOUSE_DIR}/inmates/demos/riscv/src_boot"
COMPILE_SCRIPT="${RUNPHI_SCRIPTS_DIR}/compile/jailhouse_compile.sh"
CELL_DIR="${JAILHOUSE_DIR}/configs/arm64"
RPU_BINARY_DIR="${JAILHOUSE_DIR}/inmates/demos/armr5"
RISCV_BINARY_DIR="${JAILHOUSE_DIR}/inmates/demos/riscv"
OUTPUT_DIR=${ENVIRONMENT_DIR}/install/root/tests/test_omnivisor_guest/experiments/isolation_exp/inmates

# Create directory
mkdir -p "${OUTPUT_DIR}/RPU"
mkdir -p "${OUTPUT_DIR}/RISCV"

# Copy the files to the source directory
rm -rf ${SRC_RPU_DIR}/*
cp ${SRC_RPU_BAREMETAL_DIR}/* ${SRC_RPU_DIR}
rm -rf ${SRC_RISCV_DIR}/*
cp ${SRC_RISCV_BOOT_DIR}/* ${SRC_RISCV_DIR}

# Launch the compile script
"${COMPILE_SCRIPT}" -r all

# Save the compiled files to the output directory
cp ${RPU_BINARY_DIR}/baremetal-demo.bin ${OUTPUT_DIR}/RPU/RPU-isolation-demo.bin
cp ${RPU_BINARY_DIR}/baremetal-demo_tcm.bin ${OUTPUT_DIR}/RPU/RPU-isolation-demo_tcm.bin
cp ${RISCV_BINARY_DIR}/riscv-demo.bin ${OUTPUT_DIR}/RISCV/RISCV-isolation-demo.bin

cp ${CELL_DIR}/zynqmp-kv260-RPU-inmate-demo.cell ${OUTPUT_DIR}/RPU
cp ${CELL_DIR}/zynqmp-kv260-RISCV-inmate-demo.cell ${OUTPUT_DIR}/RISCV