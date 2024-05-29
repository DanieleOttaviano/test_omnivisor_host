#!/bin/bash

# TEST DIRECTORIES
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $CURRENT_DIR
TEST_OMNV_HOST_DIR=$(dirname "${CURRENT_DIR}")
UTILITY_DIR=${TEST_OMNV_HOST_DIR}/utility
echo $UTILITY_DIR
# Results
RESULTS_DIR=${TEST_OMNV_HOST_DIR}/results
BOOT_RESULTS_DIR=${RESULTS_DIR}/boot_results
ISOLATION_RESULTS_DIR=${RESULTS_DIR}/isolation_results
TACLEBENCH_RESULTS_DIR=${RESULTS_DIR}/taclebench_results
# Experiments
EXPERIMENTS_DIR=${TEST_OMNV_HOST_DIR}/experiments
BOOT_EXP_DIR=${RESULTS_DIR}/boot_exp
ISOLATION_EXP_DIR=${RESULTS_DIR}/isolation_exp
TACLEBENCH_EXP_DIR=${EXPERIMENTS_DIR}/taclebench_exp
# Notebooks
NOTEBOOKS_DIR=${TEST_OMNV_HOST_DIR}/notebooks
IMGS_DIR=${NOTEBOOKS_DIR}/imgs


# ENVIRONMENT
target="kria"
backend="jailhouse"

# OMNIVISOR BASE DIRECTORIES
TEST_DIR=$(dirname "${TEST_OMNV_HOST_DIR}")
BASE_DIR=$(dirname "${TEST_DIR}")
# Hardcode for cross user exec
# BASE_DIR=""
SCRIPTS_DIR=${BASE_DIR}/scripts
ENVIRONMENT_DIR=${BASE_DIR}/environment/${target}/${backend}
JAILHOUSE_DIR=${ENVIRONMENT_DIR}/build/jailhouse
JAIL_CONFIG_DIR=${JAILHOUSE_DIR}/include/jailhouse/config.h
BITSTREAM_DIR=${ENVIRONMENT_DIR}/output/hardware/bitstreams
BOOT_DIR=${ENVIRONMENT_DIR}/output/boot

# TEST OMNIVISOR GUEST DIR
OVERLAYFS_DIR=${ENVIRONMENT_DIR}/install
ROOT_DIR=${OVERLAYFS_DIR}/root
TEST_OMNV_GUEST_DIR=${ROOT_DIR}/tests/test_omnivisor_guest
