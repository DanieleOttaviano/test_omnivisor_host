#!/bin/bash

# DIRECTORIES
CURRENT_DIR=$(dirname -- "$(readlink -f -- "$0")")
TEST_OMNV_DIR=$(dirname "${CURRENT_DIR}")
TEST_DIR=$(dirname "${TEST_OMNV_DIR}")
RUNPHI_DIR=$(dirname "${TEST_DIR}")
CONFIG_DIR=${RUNPHI_DIR}/environment/kria/jailhouse/build/jailhouse/include/jailhouse/config.h

define_line="#define CONFIG_XMPU_ACTIVE 1"

# Check if the file exists
if [ ! -f "$CONFIG_DIR" ]; then
    echo "File not found: $CONFIG_DIR"
    exit 1
fi

# Toggle the value of CONFIG_XMPU_ACTIVE
if grep -q "$define_line" "$CONFIG_DIR"; then
    echo "CONFIG_XMPU_ACTIVE already set to 1"
else
	echo "$define_line" >> "$CONFIG_DIR"    
	echo "CONFIG_XMPU_ACTIVE set to 1"
    # Reload Jailhouse
    bash ${TEST_OMNV_DIR}/utility/reload_jailhouse.sh
fi



