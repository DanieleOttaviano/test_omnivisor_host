#!/bin/bash

# Define the values for DIM_MB
IMG_SIZES=(1 10 20 30 40 50 60 70 80 90)

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"
SRC_DIR="${JAILHOUSE_DIR}/inmates/demos/armr5/src"
SRC_BOOT_DIR="${JAILHOUSE_DIR}/inmates/demos/armr5/src_boot"
SOURCE_FILE="${JAILHOUSE_DIR}/inmates/demos/armr5/src/boot-demo.c"
COMPILE_SCRIPT="${RUNPHI_SCRIPTS_DIR}/compile/jailhouse_compile.sh"
CELL_DIR="${JAILHOUSE_DIR}/configs/arm64"
BINARY_DIR="${JAILHOUSE_DIR}/inmates/demos/armr5"
OUTPUT_BIN_DIR="${TEST_OMNV_GUEST_DIR}/boot_exp/inmates/RPU"
OUTPUT_ELF_DIR="${OVERLAYFS_DIR}/lib/firmware"

# Create the output directory
mkdir -p "${OUTPUT_BIN_DIR}"
mkdir -p "${OUTPUT_ELF_DIR}"

rm -rf ${SRC_DIR}/*
cp ${SRC_BOOT_DIR}/* ${SRC_DIR}

# Loop through each IMG_SIZES
for IMG_SIZE in "${IMG_SIZES[@]}"
do
    # Modify the value of DIM_MB in the source file
    sed -i "s/#define DIM_MB .*/#define DIM_MB ${IMG_SIZE}/" "${SOURCE_FILE}"

    # Launch the compile script with the -r option
    "${COMPILE_SCRIPT}" -r

    # Save the compiled files to the output directory
    cp ${BINARY_DIR}/baremetal-demo.bin "${OUTPUT_BIN_DIR}/RPU-demo-${IMG_SIZE}Mb.bin"
    cp ${BINARY_DIR}/baremetal-demo.elf "${OUTPUT_ELF_DIR}/RPU-demo-${IMG_SIZE}Mb.elf"
done