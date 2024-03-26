#!/bin/bash

define_line="#define CONFIG_XMPU_ACTIVE 1"
file_path="/home/daniele/projects/runphi/environment/kria/jailhouse/build/jailhouse/include/jailhouse/config.h"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
fi

# Toggle the value of CONFIG_XMPU_ACTIVE
if grep -q "#define CONFIG_XMPU_ACTIVE 1" "$file_path"; then
    sed -i '/#define CONFIG_XMPU_ACTIVE 1/d' "$file_path"
    echo "CONFIG_XMPU_ACTIVE deleted"
else
	echo "$define_line" >> "$file_path"    
	echo "CONFIG_XMPU_ACTIVE set to 1"
fi

