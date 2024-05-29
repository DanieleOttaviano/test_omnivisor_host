#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/default_directories.sh"

# Recompile Jailhouse
${SCRIPTS_DIR}/compile/jailhouse_compile.sh -r all
# Load Jailhouse on board
${SCRIPTS_DIR}/remote/load_components_to_remote.sh -j