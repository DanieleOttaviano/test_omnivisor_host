#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"
ARMR5_DIR="${JAILHOUSE_DIR}/inmates/demos/armr5"
RISCV_DIR="${JAILHOUSE_DIR}/inmates/demos/riscv"
SRC_DIR="${ARMR5_DIR}/src"
BENCH_DIR="${SRC_DIR}/bench"
CELL_DIR="${JAILHOUSE_DIR}/configs/arm64"
COMPILE_SCRIPT="${RUNPHI_SCRIPTS_DIR}/compile/jailhouse_compile.sh"
OUTPUT_DIR="${TEST_OMNV_GUEST_DIR}/taclebench_exp/inmates"

# Get the list of directory names under bench/
directories=$(ls -d ${BENCH_DIR}/*/ | xargs -n1 basename)

# Iterate over each directory name 
for bench_name in $directories; do
    echo Compiling: $bench_name
    "$COMPILE_SCRIPT" -r -B $bench_name
    mkdir -p ${OUTPUT_DIR}/${bench_name}
    cp ${ARMR5_DIR}/baremetal-demo.bin                  ${OUTPUT_DIR}/${bench_name}/RPU-${bench_name}-demo.bin
    cp ${ARMR5_DIR}/baremetal-demo_tcm.bin              ${OUTPUT_DIR}/${bench_name}/RPU-${bench_name}-demo_tcm.bin
    cp ${CELL_DIR}/zynqmp-kv260-RPU-inmate-demo.cell    ${OUTPUT_DIR}/${bench_name}/RPU-${bench_name}.cell
    cp ${RISCV_DIR}/riscv-demo.bin                      ${OUTPUT_DIR}/${bench_name}/RISCV-${bench_name}-demo.bin
    cp ${CELL_DIR}/zynqmp-kv260-RISCV-inmate-demo.cell  ${OUTPUT_DIR}/${bench_name}/RISCV-${bench_name}.cell
done
