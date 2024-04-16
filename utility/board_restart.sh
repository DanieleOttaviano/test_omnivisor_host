#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/default_directories.sh"

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