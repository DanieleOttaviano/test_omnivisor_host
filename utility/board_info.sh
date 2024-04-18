#!/bin/bash

# BOARD IP
IP="10.210.1.150"
# BOARD SERIAL PORT
SERIAL_PORT="/dev/daniele_kria_tty01"
# BOARD PDU INDEX
BOARD_PDU_INDEX=7

# REGISTERS
TRAFFIC_GENERATOR_1=0x80010000
TRAFFIC_GENERATOR_2=0x80020000
TRAFFIC_GENERATOR_3=0x80030000
SHARED_MEM_ADDR=0x46d00000

# BOARD Paths
BOARD_TESTS_PATH="/root/tests"
BOARD_JAILHOUSE_PATH="/root/jailhouse"
BOARD_JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"
BOARD_TESTS_OMNV_PATH=${BOARD_TESTS_PATH}/test_omnivisor_guest
BOARD_EXPERIMENTS_PATH=${BOARD_TESTS_OMNV_PATH}/experiments
BOARD_BOOT_EXP_PATH=${BOARD_EXPERIMENTS_PATH}/boot_exp
BOARD_TACLEBENCH_PATH=${BOARD_EXPERIMENTS_PATH}/taclebench_exp
BOARD_ISOLATION_EXP_PATH=${BOARD_EXPERIMENTS_PATH}/isolation_exp
BOARD_ISOLATION_INMATES_PATH=${BOARD_ISOLATION_EXP_PATH}/inmates
BOARD_UTILITY_DIR=${BOARD_TESTS_OMNV_PATH}/utility
BOARD_RESULTS_PATH=${BOARD_TESTS_OMNV_PATH}/results
BOARD_BOOT_RESULTS_PATH=${BOARD_RESULTS_PATH}/boot_results
BOARD_ISOLATION_RESULTS_PATH=${BOARD_RESULTS_PATH}/isolation_results
BOARD_TACLEBENCH_RESULTS_PATH=${BOARD_RESULTS_PATH}/taclebench_results
BOARD_OUTPUT_LOG="/dev/null" #"/tmp/boot_time.log"

#TEMPORAL ISOLATION MIN AND MAX
BOARD_MIN_APU_BANDWIDTH=5
BOARD_MIN_FPGA_BANDWIDTH=5
BOARD_MIN_RPU_BANDWIDTH=5

BOARD_MAX_APU_BANDWIDTH=950
BOARD_MAX_FPGA_BANDWIDTH=14
BOARD_MAX_RPU_BANDWIDTH=10