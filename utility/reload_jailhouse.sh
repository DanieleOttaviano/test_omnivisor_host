#!/bin/bash

# DIRECTORIES
CURRENT_DIR=$(dirname -- "$(readlink -f -- "$0")")
TEST_OMNV_DIR=$(dirname "${CURRENT_DIR}")
TEST_DIR=$(dirname "${TEST_OMNV_DIR}")
RUNPHI_DIR=$(dirname "${TEST_DIR}")
RUNPHI_SCRIPTS_DIR=${RUNPHI_DIR}/scripts

# Recompile Jailhouse
${RUNPHI_SCRIPTS_DIR}/compile/jailhouse_compile.sh -r
# Load Jailhouse on board
${RUNPHI_SCRIPTS_DIR}/remote/load_components_to_remote.sh -j