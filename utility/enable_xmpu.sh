#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/default_directories.sh"

define_line="#define CONFIG_XMPU_ACTIVE 1"
# Check if the file exists
if [ ! -f "$JAIL_CONFIG_DIR" ]; then
    echo "File not found: $JAIL_CONFIG_DIR"
    exit 1
fi

# Toggle the value of CONFIG_XMPU_ACTIVE
if grep -q "$define_line" "$JAIL_CONFIG_DIR"; then
    echo "CONFIG_XMPU_ACTIVE already set to 1"
else
	echo "$define_line" >> "$JAIL_CONFIG_DIR"    
	echo "CONFIG_XMPU_ACTIVE set to 1"
    # Reload Jailhouse
    echo "Compiling and Reloading Jailhouse..." 
    bash ${TEST_OMNV_HOST_DIR}/utility/reload_jailhouse.sh > /dev/null 2>&1
    echo "Jailhouse Reloaded"
fi



