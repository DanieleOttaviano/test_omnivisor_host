#!/bin/bash

usage() {
	echo -e "Usage: $0 \r\n \
        This script Start the Isolation test on the selected processor with the selected disturb sources:\r\n \
            [-c <core under isolation test> (RPU, RISCV)]\r\n \
            [-d <source of disturb> (APU, RPU1, FPGA, ALL)]\r\n \
            [-S apply spatial isolation (enable XMPUs)]\r\n \
            [-T apply temporal isolation (enable QoS + Memguard)]\r\n \
            [-s save the results]\r\n \
            [-h help]" 1>&2
    exit 1
}

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

# BOARD INFO
source ${UTILITY_DIR}/board_info.sh 

# Name of the SCRIPT on BOARD
SCRIPT_NAME="isolation_exp"
# SLEEP TIME BEFORE INTERFERENCE
TEST_DURATION=20 # seconds
SOLO_TIME=2 # seconds
FULL_INTERFERENCE_TIME=$(( TEST_DURATION - SOLO_TIME ))
SPAT_ISOL=0
TEMP_ISOL=0
SAVE=0

while getopts "c:d:STsph" o; do
    case "${o}" in
        c)
			core=${OPTARG}
            TEST_NAME=$core
            ;;
        d)
			disturb=${OPTARG}
            TEST_NAME=${TEST_NAME}_${disturb}
            if [[ "${disturb}" == "ALL" ]]; then
                SOLO_TIME=4
                FULL_INTERFERENCE_TIME=$(( TEST_DURATION - (SOLO_TIME * 4) ))
            fi
            ;;
        S)
            SPAT_ISOL=1
			TEST_NAME=${TEST_NAME}_spt
            ;;
        T)
            TEMP_ISOL=1
            TEST_NAME=${TEST_NAME}_tmp
            ;;
        s)
            SAVE=1
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Check Inputs
if [[ $core != "RPU" && $core != "RISCV" ]]; then
	echo "Error: Invalid core under test specified: ${core}"
    echo "Valid cores: RPU, RISCV"
	usage
	exit 1
fi
if [[ $disturb != "APU" && $disturb != "RPU1" && $disturb != "FPGA" && $disturb != "ALL" && $disturb != "NONE" ]]; then
	echo "Error: Invalid disturb source specified: ${disturb}"
    echo "Valid sources: NONE, APU, RPU1, FPGA, ALL"
	usage
	exit 1
fi
echo "Test name: ${TEST_NAME} (duration: ${TEST_DURATION}s)"
echo "Spatial Isolation: ${SPAT_ISOL}"
echo "Temporal Isolation: ${TEMP_ISOL}"
echo "Save txt results: ${SAVE}"
echo ""


## PRE-TEST

# Create group on core0 to execute the tests
ssh root@${IP} "mkdir /sys/fs/cgroup/cpuset/test &&
        echo 0 > /sys/fs/cgroup/cpuset/test/cpuset.cpus &&
        echo 0 > /sys/fs/cgroup/cpuset/test/cpuset.mems" > /dev/null 2>&1

# If RPU1 preload in memory the RPU1 membomb
if [[ "${disturb}" == "RPU1"  || "${disturb}" == "ALL" ]]; then
    ssh root@${IP} "cp ${BOARD_ISOLATION_INMATES_PATH}/RPU1/RPU1-${core}-membomb-demo.elf /lib/firmware"
    ssh root@${IP} "cat /lib/firmware/RPU1-${core}-membomb-demo.elf > /dev/null"
fi

# Apply Spatial Isolation
if [[ $SPAT_ISOL -eq 1 ]]; then
    bash ${UTILITY_DIR}/enable_xmpu.sh 
else
    bash ${UTILITY_DIR}/disable_xmpu.sh
fi

# Start Omnivisor
echo "Starting Omnivisor"
ssh root@${IP} "bash ${BOARD_UTILITY_DIR}/jailhouse_start.sh" > /dev/null 2>&1

echo "Starting bandwidth regulation"
# Apply Temporal Isolation
if [[ "${TEMP_ISOL}" -eq "1" ]]; then
    # 5mb/s of bandwidth
    ssh root@${IP} "bash ${BOARD_UTILITY_DIR}/apply_temp_reg.sh -B 5 -r -f -a" # > /dev/null 2>&1
else
    # 950mb/s of bandwidth is enough to have the same behaviour as without temporal isolation
    ssh root@${IP} "bash ${BOARD_UTILITY_DIR}/apply_temp_reg.sh -B 950 -r -f -a" # > /dev/null 2>&1
fi


## START TEST
# disturb (bomber) and test are started in parallel
echo "Starting Test on ${core}"
ssh root@${IP} "
    bash ${BOARD_ISOLATION_EXP_PATH}/${SCRIPT_NAME}.sh -c ${core} -n ${TEST_NAME} &
    bash ${BOARD_ISOLATION_EXP_PATH}/${SCRIPT_NAME}_bomber.sh -c ${core} -d ${disturb} -S ${SPAT_ISOL}" #> /dev/null 2>&1


echo "Stopping bandwidth regulation"
ssh root@${IP} "${BOARD_JAILHOUSE_PATH}/tools/jailhouse qos disable"

# Disable Omnivisor
echo "Stopping Omnivisor"
ssh root@${IP} "${BOARD_JAILHOUSE_PATH}/tools/jailhouse disable" # > /dev/null 2>&1
# echo "/root/jailhouse/tools/jailhouse disable" > ${SERIAL_PORT}

# Save Results from memory (BOARD)
ssh root@${IP} "${BOARD_ISOLATION_EXP_PATH}/save_shm.sh ${TEST_NAME}"

# Save Results
if [[ ${SAVE} -eq 1 ]]; then
    echo "Saving results"
    scp -r "root@${IP}:${BOARD_ISOLATION_RESULTS_PATH}/${TEST_NAME}.txt" "${ISOLATION_RESULTS_DIR}/"
    cat ${ISOLATION_RESULTS_DIR}/${TEST_NAME}.txt 
fi
