#!/bin/bash

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"
source ${UTILITY_DIR}/board_info.sh 
source /etc/profile.d/00-aliases.sh


vars=("$@")
echo "${vars[@]}"

reboots=0

while :; do
    echo "Parent script, on"
    echo "${TACLEBENCH_EXP_DIR}/start_allout_taclebench.sh ${vars[@]} -f taclebench.state"
    # exit 1

    bash ${TACLEBENCH_EXP_DIR}/start_allout_taclebench.sh "${vars[@]}" -f taclebench.state
    
    if [[ $? -ne 43 ]]; then
        mv taclebench.state taclebench.state.$(date +%s%3N)
        break
    fi

    reboots=`echo "${reboots} + 1" | bc`
    printf "\n\nReboot # ${reboots}\n\n"

    bash -c "/tools/PDUPowerExpect.sh ${BOARD_PDU_INDEX}" 2>&1 > /dev/null
    
    sleep 5

    bash "${UTILITY_DIR}/board_restart.sh"

    sleep 15

    for ((i=0; i < 60; i++)); do
        ping -c 1 ${IP}
        if [[ $? -eq 0 ]]; then break; fi
        sleep 1
    done

    for ((i=0; i < 10; i++)); do
        ssh root@${IP} 'true'
        if [[ $? -eq 0 ]]; then break; fi
        sleep 1
    done


    # mv taclebench.state taclebench.state.$(date +%s%3N)
done