#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script launch the VM Boot test on a ZCU board on the specified processor:\r\n \
      [-r <repetitions>]\r\n \
      [-c <core> (APU, RPU, RISCV)]\r\n \
      [-s save the results on the host machine]\r\n \
      [-h help]" 1>&2
    exit 1
}

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

# BOARD INFO
source ${UTILITY_DIR}/board_info.sh 

SAVE=0
#chrt -f 99 ./boot_time.sh -r 100 -c APU
while getopts "c:r:sh" o; do
    case "${o}" in
        r)
			repetitions=${OPTARG}
            ;;
        c)
			core=${OPTARG}
            ;;
        s)
            echo "Save txt results"
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
if [[ $repetitions -lt 1 ]]; then
	echo "Error: Invalid number of repetitions specified."
	usage
	exit 1
fi
if [[ $core != "APU" && $core != "RPU" && $core != "RISCV" ]]; then
	echo "Error: Invalid core specified."
	usage
	exit 1
fi

if [[ $core == "APU" ]]; then
    max_time=7
elif [[ $core == "RPU" ]]; then
    max_time=7
elif [[ $core == "RISCV" ]]; then
    max_time=7
fi

test_time=$(( $max_time * $repetitions ))

echo "Launching Boot Time Test on ${core} (${repetitions} repetitions)"
echo "Test Time: ${test_time} seconds ($(( ${test_time} / 60 )) minutes)"

echo "chrt -f 70 ${BOARD_BOOT_EXP_PATH}/boot_time.sh -r ${repetitions} -c ${core}" > ${SERIAL_PORT}

# Wait until "Finish!" is not printed
# while read -r line; do
#     if [[ $line == *"Finish!"* ]]; then
#         break
#     fi
#     sleep 5
# done < ${SERIAL_PORT}
# echo "clear" > ${SERIAL_PORT}

# To do ... wait for the test to finish using ssh
sleep $test_time

# Save Results
if [[ ${SAVE} -eq 1 ]]; then
    scp -r root@${IP}:${BOARD_BOOT_RESULTS_PATH}/boot_${core} ${BOOT_RESULTS_DIR}
fi