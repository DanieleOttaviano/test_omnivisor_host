#!/bin/bash

# DIRECTORIES
CURRENT_DIR=$(dirname -- "$(readlink -f -- "$0")")
TEST_OMNV_DIR=$(dirname "${CURRENT_DIR}")
UTILITY_DIR=${TEST_OMNV_DIR}/utility

# BOARD INFO
source ${UTILITY_DIR}/board_info.sh

#reboot the board
source "/etc/profile.d/00-aliases.sh"
board_reboot daniele SD 2>&1 > /dev/null

sleep 60 ## TO ADJUST ...

# Login
echo "root" > ${SERIAL_PORT} 
sleep 1
echo "root" > ${SERIAL_PORT} 

echo "Logged in"