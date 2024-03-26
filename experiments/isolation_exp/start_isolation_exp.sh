#!/bin/bash

usage() {
	echo -e "Usage: $0 \r\n \
        This script Start the Isolation test on the selected processor with the selected disturb sources:\r\n \
            [-c <core under isolation test> (RPU, RISCV)]\r\n \
            [-d <source of disturb> (APU, RPU1, FPGA, ALL)]\r\n \
            [-S apply spatial isolation (XMPUs)]\r\n \
            [-T apply temporal isolation (QoS + Memguard)]\r\n \
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
echo "Print and save png results: ${PRINT}"
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
    bash ${UTILITY_DIR}/enable_xmpu.sh > /dev/null 2>&1
else
    bash ${UTILITY_DIR}/disable_xmpu.sh > /dev/null 2>&1
fi

# Start Omnivisor
echo "Starting Omnivisor"
ssh root@${IP} "bash ${BOARD_UTILITY_PATH}/jailhouse_start.sh" > /dev/null 2>&1

echo "Starting bandwidth regulation"
# Apply Temporal Isolation
if [[ "${TEMP_ISOL}" -eq "1" ]]; then
    # ssh root@${IP} "bash ${BOARD_UTILITY_PATH}/apply_temp_reg.sh -r -f -a" > /dev/null 2>&1 &
    ssh root@${IP} "bash ${BOARD_UTILITY_PATH}/apply_temp_reg.sh -B 5 -r -f -a" > /dev/null 2>&1
else
    ssh root@${IP} "bash ${BOARD_UTILITY_PATH}/apply_temp_reg.sh -B 950 -r -f -a" > /dev/null 2>&1
fi


## START TEST
echo "Starting Test on ${core}"
ssh root@${IP} "
    bash ${BOARD_ISOLATION_EXP_PATH}/${SCRIPT_NAME}.sh -c ${core} -n ${TEST_NAME} &
    bash ${BOARD_ISOLATION_EXP_PATH}/${SCRIPT_NAME}_bomber.sh -c ${core} -d ${disturb} -S ${SPAT_ISOL}" #> /dev/null 2>&1

# # Time without interference
# sleep ${SOLO_TIME}

# # Start the interferences
# if [[ $disturb == "APU" || $disturb == "ALL" ]]; then
#     echo "Starting APU membomb"
#     if [[ "${SPAT_ISOL}" -eq "0" ]]; then
#         # Without spatial isolation the APU would crash the system
#         # Therefore to save the experiemnt we do not start the APU
#         # ssh root@${IP} "${INMATES_PATH}/APU/flip_bit"
#         :
#     else
#         # Start APU membomb
#         ssh root@${IP} "${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c1 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &
#                         ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c2 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &
#                         ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c3 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &" &
#     fi

#     if [[ $disturb == "ALL" ]]; then
#         sleep ${SOLO_TIME}
#     else
#         sleep ${FULL_INTERFERENCE_TIME}
#     fi
# fi
# if [[ $disturb == "RPU1" || $disturb == "ALL" ]]; then
#     # Start RPU1 membomb
#     echo "Starting RPU1 membomb"
#     ssh root@${IP} "cd /lib/firmware && 
#                     echo RPU1-${core}-membomb-demo.elf > /sys/class/remoteproc/remoteproc1/firmware && 
#                     echo start > /sys/class/remoteproc/remoteproc1/state" &

#     if [[ $disturb == "ALL" ]]; then
#         sleep ${SOLO_TIME}
#     else
#         sleep ${FULL_INTERFERENCE_TIME}
#     fi
# fi
# if [[ $disturb == "FPGA" || $disturb == "ALL" ]]; then
#     # Start traffic generators
#     echo "Starting FPGA Traffic Generator 1"
#     if [[ $core == "RPU" ]]; then
#         ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_1} 64 1" &
#     elif [[ $core == "RISCV" ]]; then
#         ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_2} 64 1" &
#     fi

#     # If ALL power on another traffic generator
#     if [[ $disturb == "ALL" ]]; then
#         sleep ${SOLO_TIME}
#         echo "Starting FPGA Traffic Generator 2"
#         ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_3} 64 1" &
#         sleep ${SOLO_TIME}
#     else
#         sleep ${FULL_INTERFERENCE_TIME}
#     fi
# fi


# if [[ "${TEMP_ISOL}" -eq "1" ]]; then
echo "Stopping bandwidth regulation"
ssh root@${IP} "/root/jailhouse/tools/jailhouse qos disable"
# fi

# Disable Omnivisor
echo "Stopping Omnivisor"
ssh root@${IP} "/root/jailhouse/tools/jailhouse disable" # > /dev/null 2>&1
# echo "/root/jailhouse/tools/jailhouse disable" > ${SERIAL_PORT}

## STOP TEST
if [[ $disturb == "APU" || $disturb == "ALL" ]]; then
    # Stop APU membomb
    echo "Stopping APU membomb"
    ssh root@${IP} "killall bandwidth"
    # echo "killall bandwidth" > ${SERIAL_PORT}
fi
if [[ $disturb == "RPU1" || $disturb == "ALL" ]]; then
    # Stop RPU1 membomb
    echo "Stopping RPU1 membomb"
    ssh root@${IP} "echo stop > /sys/class/remoteproc/remoteproc1/state"
    # echo "echo stop > /sys/class/remoteproc/remoteproc1/state" > ${SERIAL_PORT}
fi
if [[ $disturb == "FPGA" || $disturb == "ALL" ]]; then
    # Stop traffic generators
    echo "Stopping FPGA Traffic Generators"
    ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_1} 64 0"
    ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_2} 64 0"
    ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_3} 64 0"
    # echo "devmem ${TRAFFIC_GENERATOR_1} 64 0" > ${SERIAL_PORT}
    # echo "devmem ${TRAFFIC_GENERATOR_2} 64 0" > ${SERIAL_PORT}
    # echo "devmem ${TRAFFIC_GENERATOR_3} 64 0" > ${SERIAL_PORT}
fi

# Save Results from memory (BOARD)
ssh root@${IP} "${BOARD_UTILITY_PATH}/save_shm.sh ${TEST_NAME}"

# Save Results
if [[ ${SAVE} -eq 1 ]]; then
    echo "Saving results"
    scp -r "root@${IP}:${BOARD_ISOLATION_RESULTS_PATH}/${TEST_NAME}.txt" "${ISOLATION_RESULTS_DIR}/"
    cat ${ISOLATION_RESULTS_DIR}/${TEST_NAME}.txt 
fi

