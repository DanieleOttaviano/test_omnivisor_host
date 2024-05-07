#!/bin/bash

usage() {
    echo -e "\r\n\
Usage: $0 -p -f \r\n\
This script automatize the run of the taclebench tests both on FPGA and RPU.\r\n\
The full experiments' set is fairly time consuming and we offer a default simplified version\r\n\
with prove the validity of the tests: the binary search is only performing 5 repetitions and\r\n\
having a easy goal of 1.5x slowdown.\r\n\
    [-p ] \r\n\
    [-f ] " 1>&2

    exit 1
}

PAPER=0
FULL=0

while getopts "pfh" o; do
    case "${o}" in
        p)
            PAPER=1
            if [[ $FULL -eq 1 ]]; then
                echo -e "-p and -f cannot be used at the same time" 1>&2
                exit
            fi
            ;;
        f)
            FULL=1
            if [[ $PAPER -eq 1 ]]; then
                echo -e "-p and -f cannot be used at the same time" 1>&2
                exit
            fi
            ;;
        # b)
        #     if [[ $TEMPORAL -eq 1 ]]; then
        #         echo -e "ERROR: -t and -b cannot be used at the same time" 1>&2
        #     fi
        #     FULL_BINARY=1
        #     ;;
        # t)
        #     if [[ $FULL_BINARY -eq 1 ]]; then
        #         echo -e "ERROR: -t and -b cannot be used at the same time" 1>&2
        #     fi
        #     BANDWIDTH=${OPTARG}
        #     TEMPORAL=1
        #     ;;
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
if [[ $FULL -eq 1 ]]; then
    if [[ $FULL -eq 1 ]]; then
        echo -e "-t and -b cannot be used at the same time" 1>&2
    fi
    ./start_filestate_taclebench.sh -c RPU -r 30  -s
    bash ${UTILITY_DIR}/board_restart.sh
    ./start_filestate_taclebench.sh -c RISCV -r 30 -s
elif [[ $PAPER -eq 1 ]]; then
    ./start_filestate_taclebench.sh -c RPU -r 30  -s
    bash ${UTILITY_DIR}/board_restart.sh
    ./start_filestate_taclebench.sh -c RISCV -r 30 -s
else
    ./start_filestate_taclebench.sh -c RPU -r 1  -s
    bash ${UTILITY_DIR}/board_restart.sh
    ./start_filestate_taclebench.sh -c RISCV -r 1 -s
fi

bash ${UTILITY_DIR}/board_restart.sh

if [[ $FULL -eq 1 ]]; then
    if [[ $PAPER -eq 1 ]]; then
        echo -e "-p and -f cannot be used at the same time" 1>&2
    fi
    ./start_filestate_taclebench.sh -c RPU -r 30 -s -S 1.2
    bash ${UTILITY_DIR}/board_restart.sh
    ./start_filestate_taclebench.sh -c RISCV -r 30 -s -S 1.2
elif [[ $PAPER -eq 1 ]]; then
    ./start_filestate_taclebench.sh -c RPU -r 30 -s -q
    bash ${UTILITY_DIR}/board_restart.sh
    ./start_filestate_taclebench.sh -c RISCV -r 30 -s -q
else
    ./start_filestate_taclebench.sh -c RPU -r 1 -s -q
    bash ${UTILITY_DIR}/board_restart.sh
    ./start_filestate_taclebench.sh -c RISCV -r 1 -s -q
fi
