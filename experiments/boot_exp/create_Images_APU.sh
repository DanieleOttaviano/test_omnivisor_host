#!/bin/bash

# Images sizes in Megabytes
IMG_SIZES=(1 10 20 30 40 50 60 70 80 90)

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"
COMPILE_SCRIPT="${RUNPHI_SCRIPTS_DIR}/compile/jailhouse_compile.sh"
SOURCE_FILE="${JAILHOUSE_DIR}/inmates/demos/arm/boot-demo.c"
BINARY_DIR="${JAILHOUSE_DIR}/inmates/demos/arm64"
CELL_DIR="${JAILHOUSE_DIR}/configs/arm64"
OUTPUT_BIN_DIR="${TEST_OMNV_GUEST_DIR}/experiments/boot_exp/inmates/APU"

# Create the output directory
mkdir -p "${OUTPUT_BIN_DIR}"

# Loop through each IMG_SIZES
for IMG_SIZE in "${IMG_SIZES[@]}"
do
    # Modify the value of DIM_MB in the source file
    sed -i "s/#define DIM_MB .*/#define DIM_MB ${IMG_SIZE}/" "${SOURCE_FILE}"

    # Launch the compile script
    "${COMPILE_SCRIPT}"

    # Save the compiled files to the output directory
    cp ${BINARY_DIR}/boot-demo.bin "${OUTPUT_BIN_DIR}/APU-demo-${IMG_SIZE}Mb.bin"
done

cp ${CELL_DIR}/zynqmp-kv260-APU-inmate-demo.cell "${OUTPUT_BIN_DIR}/" 