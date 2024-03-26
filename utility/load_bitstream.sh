#!/bin/bash

# DIRECTORIES
CURRENT_DIR=$(dirname -- "$(readlink -f -- "$0")")
TEST_OMNV_DIR=$(dirname "${CURRENT_DIR}")
UTILITY_DIR=${TEST_OMNV_DIR}/utility
TEST_DIR=$(dirname "${TEST_OMNV_DIR}")
RUNPHI_DIR=$(dirname "${TEST_DIR}")
RUNPHI_SCRIPTS_DIR=${RUNPHI_DIR}/scripts
BITSTREAM_DIR=${RUNPHI_DIR}/environment/kria/jailhouse/output/hardware/bitstreams
BOOT_DIR=${RUNPHI_DIR}/environment/kria/jailhouse/output/boot

# BOARD INFO
source ${UTILITY_DIR}/board_info.sh

if [ -z "$1" ]; then
    echo "No input bitstream specified."
    exit 1
fi

BITSTREAM_NAME="$1"
echo "bitstream name: ${BITSTREAM_NAME}"

# create BOOT.BIN from bitstream
if [ -f "${BITSTREAM_DIR}/${BITSTREAM_NAME}" ]; then
    if diff -q "${BITSTREAM_DIR}/${BITSTREAM_NAME}" "${BOOT_DIR}/system.bit" >/dev/null; then
        echo "bitstream already loaded"
        exit 1
    fi
    cp "${BITSTREAM_DIR}/${BITSTREAM_NAME}" "${BOOT_DIR}/system.bit"
else
    echo "Bitstream file not found."
    exit 1
fi

# Compile BOOT.BIN
bash ${RUNPHI_SCRIPTS_DIR}/compile/bootgen_compile.sh

# Load BOOT.BIN on the board
bash ${RUNPHI_SCRIPTS_DIR}/remote/load_boot_imgs_to_remote.sh -o

# Sync board
echo "sync" > ${SERIAL_PORT} 

# Reboot board
bash ${UTILITY_DIR}/board_restart.sh