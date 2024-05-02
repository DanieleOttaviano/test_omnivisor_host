#!/bin/bash

usage() {
    echo -e "\r\n\
Usage: $0 [-t BANDWIDTH] [-b] \r\n\
This script automatize the run of the taclebench tests both on FPGA and RPU.\r\n\
The full experiments' set is fairly time consuming and we offer a default simplified version\r\n\
with prove the validity of the tests: the binary search is only performing 5 repetitions and\r\n\
having a easy goal of 1.5x slowdown.\r\n\
    [-t <BANDWIDTH> replace the binary search with a fixed bandwidth temporal isolation]\r\n\
    [-b] apply the full binary research as in the paper" 1>&2

    exit 1
}

TEMPORAL=0
FULL_BINARY=0
BANDWIDTH=0

while getopts "bt:" o; do
    case "${o}" in
        b)
            if [[ $TEMPORAL -eq 1 ]]; then
                echo -e "ERROR: -t and -b cannot be used at the same time" 1>&2
            fi
            FULL_BINARY=1
            ;;
        t)
            if [[ $FULL_BINARY -eq 1 ]]; then
                echo -e "ERROR: -t and -b cannot be used at the same time" 1>&2
            fi
            BANDWIDTH=${OPTARG}
            TEMPORAL=1
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

# Clean Restart Board
echo "Clean Restart Board..."
bash ${UTILITY_DIR}/board_restart.sh

# Launch Tests
echo "**************** Launch Tests ****************"
./start_filestate_taclebench.sh -c RPU -r 30  -s
./start_filestate_taclebench.sh -c RISCV -r 30 -s

if [[ $FULL_BINARY -eq 1 ]]; then
    if [[ $TEMPORAL -eq 1 ]]; then
        echo -e "-t and -b cannot be used at the same time" 1>&2
    fi
    ./start_filestate_taclebench.sh -c RPU -r 30 -s -S 1.2
    ./start_filestate_taclebench.sh -c RISCV -r 30 -s -S 1.2
elif [[ $TEMPORAL -eq 1 ]]; then
    ./start_filestate_taclebench.sh -c RPU -r 30 -s -d -T -B $BANDWIDTH
    ./start_filestate_taclebench.sh -c RISCV -r 30 -s -d -T -B $BANDWIDTH
else
    ./start_filestate_taclebench.sh -c RPU -r 5 -s -S 1.5
    ./start_filestate_taclebench.sh -c RISCV -r 5 -s -S 1.5
fi