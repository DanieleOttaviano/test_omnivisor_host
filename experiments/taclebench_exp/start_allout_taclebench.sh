#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script launch the taclebench suit on the selected core:\r\n \
      [-c <core under isolation test> (RPU, RISCV)]\r\n \
      [-d apply disturb from all the managers (APU, RPU-1, FPGA)]\r\n \
      [-r <num> number of repetitions]\r\n \
      [-T apply temporal isolation (QoS + Memguard)]\r\n \
      [-s save the results]\r\n \
      [-p print the results in and save in imgs directory]\r\n \
      [-e <name_ext> saved file name extension]\r\n \
      [-f <file_state_name> save state on file with passed filename]\r\n \
      [-S <target_slowdown> binary search for target slowdown]\r\n \
      [-h help]" 1>&2

    exit 1
}

# BOARD'S DIRECTORIES
JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"
TACLE_EXP_PATH="/root/tests/test_omnivisor_guest/experiments/taclebench_exp"
BENCH_DIR="${TACLE_EXP_PATH}/inmates"
CELL_PATH="/root/jailhouse/configs/arm64"
# UTILITY_DIR="/root/tests/test_omnivisor_guest/utility"

# LOCAL DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"
# CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# TEST_OMNV_HOST_DIR=$(dirname "${CURRENT_DIR}")
# UTILITY_DIR=${TEST_OMNV_HOST_DIR}/utility
RESULTS_DIR=${TEST_OMNV_HOST_DIR}/results/taclebench_results

# TACLEBENCH_EXP_DIR=$(dirname -- "$(readlink -f -- "$0")")
# TEST_OMNV_DIR=$(dirname "${TACLEBENCH_EXP_DIR}")
# RESULTS_DIR=${TEST_OMNV_DIR}/results/taclebench_results
# UTILITY_DIR=${TEST_OMNV_DIR}/utility
# TARGET_EXP_PATH="/root/tests/test_omnivisor_guest/taclebench_exp"
# RES_DIR="${TACLEBENCH_EXP_DIR}/results/"

# BOARD INFO
source ${UTILITY_DIR}/board_info.sh 
source "/etc/profile.d/00-aliases.sh"

# Wait time for the test to finish
DISTURB=0
TEMP_ISOL=0
SAVE=0
PRINT=0
REPETITIONS=1
KEEP=0
SEARCH=0
# TARGET_SLOWDOWN=1.2

# Default values
SCRIPT_NAME="start_taclebench"
NAME_EXTENSION=""

BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH
TMP_BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH

LAST_BANDWIDTH=0
HIGHER_BOUND_BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH
LOWER_BOUND_BANDWIDTH=0

RPU_BANDWIDTH=$BOARD_MAX_RPU_BANDWIDTH
FPGA_BANDWIDTH=$BOARD_MAX_FPGA_BANDWIDTH
APU_BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH

TMP_RPU_BANDWIDTH=10
TMP_FPGA_BANDWIDTH=14
TMP_APU_BANDWIDTH=950

LAST_RPU_BANDWIDTH=0
LAST_FPGA_BANDWIDTH=0
LAST_APU_BANDWIDTH=0

TIMEOUT_SECONDS=900
TIMEOUT_MINUTES=3

CURRENT_BENCH=""
PREVIOUS_BENCH=0

it=0
found_target_bandwidth=0
it_under_target=1

STATE_FILENAME=/dev/null

while getopts "B:c:dTsphe:r:kS:f:" o; do
    case "${o}" in
        B)
            BANDWIDTH=${OPTARG}
            ;;
        k)
            KEEP=1
            ;;
        c)
            core=${OPTARG}
            if [[ $core == "RPU" ]]; then
                TIMEOUT_SECONDS=300
            fi
            NAME_EXTENSION="_${core}"
            ;;
        d)
            DISTURB=1
            NAME_EXTENSION="${NAME_EXTENSION}_ALL"
            ;;
        r)
            REPETITIONS=${OPTARG}
            ;;
        T)
            TEMP_ISOL=1
            BANDWIDTH=$BOARD_MIN_APU_BANDWIDTH
            NAME_EXTENSION="${NAME_EXTENSION}_tmp"
            ;;
        s)
            SAVE=1
            ;;
        p)
            PRINT=1
            ;;
        h)
            usage
            ;;
        e)
            NAME_EXTENSION="${NAME_EXTENSION}_${OPTARG}"
            ;;
        f)
            SAVE_STATE_ON_FILE=1
            STATE_FILENAME=${OPTARG}

            # exit 1
            ;;
        S)
            SEARCH=1
            TARGET_SLOWDOWN=${OPTARG}
            # KEEP=0
            DISTURB=1
            SEARCH_ITERS=$REPETITIONS
            REPETITIONS=15
            ;;
        *)
            usage
            ;;
    esac
done

save_on_file() {
    echo "$CURRENT_BENCH $it $rep $BANDWIDTH $HIGHER_BOUND_BANDWIDTH $LOWER_BOUND_BANDWIDTH $found_target_bandwidth $it_under_target $slowdowns_list" > ${STATE_FILENAME}
}

if [[ $SAVE_STATE_ON_FILE -eq 1 ]]; then
    if [[ -f ${STATE_FILENAME} ]]; then
        read -r CURRENT_BENCH it rep BANDWIDTH HIGHER_BOUND_BANDWIDTH LOWER_BOUND_BANDWIDTH found_target_bandwidth it_under_target slowdowns_list <${STATE_FILENAME}
        PREVIOUS_BENCH=1
    fi
    echo "CURRENT_BENCH: $CURRENT_BENCH"
    echo "it: $it"
    echo "rep: $rep"
    echo "BANDWIDTH: $APU_BANDWIDTH"
    echo "HIGHER_BOUND_BANDWIDTH : $HIGHER_BOUND_BANDWIDTH"
    echo "LOWER_BOUND_BANDWIDTH : $LOWER_BOUND_BANDWIDTH"
    echo "PREVIOUS_BENCH: $PREVIOUS_BENCH"
    echo "found_target_bandwidth: $found_target_bandwidth"
    echo "it_under_target: $it_under_target"
    echo "slowdowns_list: $slowdowns_list"
fi

# Check Inputs
if [[ $core != "RPU" && $core != "RISCV" ]]; then
	echo "Error: Invalid core under test specified: ${core}"
    echo "Valid cores: RPU, RISCV"
	usage
	exit 1
fi
if [[ $REPETITIONS -lt 1 ]]; then
    echo "Error: Invalid number of repetitions specified: ${REPETITIONS}"
    usage
    exit 1
fi

echo "Test name: <benchname>${NAME_EXTENSION}"
echo "ALL Interference: ${DISTURB}"
echo "BANDWIDTH:${BANDWIDTH}"
echo "Save txt results: ${SAVE}"
echo "Print and save png results: ${PRINT}"
echo "Repetitions: ${REPETITIONS}"
echo ""

echo "Enable XMPU if disabled"
timeout -s 2 1m bash ${UTILITY_DIR}/enable_xmpu.sh
if [[ $? -ne 0 ]]; then exit 43; fi

echo "Create group on core0 to execute the tests"
timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "mkdir /sys/fs/cgroup/cpuset/test &&
        echo 0 > /sys/fs/cgroup/cpuset/test/cpuset.cpus &&
        echo 0 > /sys/fs/cgroup/cpuset/test/cpuset.mems"
if [[ $? -eq 128 ]] || [[ $? -eq 255 ]]; then exit 43; fi

# Start Omnivisor
echo "Starting Omnivisor"
timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "bash ${BOARD_UTILITY_DIR}/jailhouse_start.sh"
if [[ $? -ne 0 ]]; then exit 43; fi

if [[ ${SEARCH} -eq 0 ]]; then
    # Apply Temporal Isolation
    echo "Starting bandwidth regulation"
    timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "bash ${BOARD_UTILITY_DIR}/apply_temp_reg.sh -B ${APU_BANDWIDTH} -r -f -a"
    if [[ $? -ne 0 ]]; then exit 43; fi
fi

# Apply DISTURB
# Preload in memory the RPU1 membomb
if [[ "${DISTURB}" -eq "1" ]]; then
    
    timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "cp ${BOARD_ISOLATION_INMATES_PATH}/RPU1/RPU1-${core}-membomb-demo.elf /lib/firmware"
    if [[ $? -ne 0 ]]; then exit 43; fi

    timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "cat /lib/firmware/RPU1-${core}-membomb-demo.elf > /dev/null"
    if [[ $? -ne 0 ]]; then exit 43; fi

    # Start RPU1 membomb
    echo "Starting RPU1 membomb"
    timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "cd /lib/firmware;
                    echo stop > /sys/class/remoteproc/remoteproc1/state;
                    echo RPU1-${core}-membomb-demo.elf > /sys/class/remoteproc/remoteproc1/firmware;
                    echo start > /sys/class/remoteproc/remoteproc1/state"
    if [[ $? -ne 0 ]]; then exit 43; fi

    # Start APU membomb
    echo "Starting APU membomb"
    timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c1 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &
                    ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c2 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &
                    ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c3 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &"
    if [[ $? -ne 0 ]]; then exit 43; fi
    
    # Start FPGA membomb
    echo "Starting FPGA membomb"
    if [[ $core == "RPU" ]]; then
        
        timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_1} 64 1"
        if [[ $? -ne 0 ]]; then exit 43; fi
    elif [[ $core == "RISCV" ]]; then
        timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_2} 64 1"
        if [[ $? -ne 0 ]]; then exit 43; fi
        
    fi 
    timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_3} 64 1"
    if [[ $? -ne 0 ]]; then exit 43; fi
    

    ## START TEST
    echo "[$(date +"%H:%M:%S")] Starting Taclebench Test on ${core}"


    # Remove kernel prints
    timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "echo 1 > /proc/sys/kernel/printk"
    if [[ $? -ne 0 ]]; then exit 43; fi
    
fi

# Get the list of directory names under bench/
directories=`timeout -s 2 ${TIMEOUT_MINUTES}m ssh root@${IP} "ls -d ${BENCH_DIR}/*/ | xargs -n1 basename"`
if [[ $? -ne 0 ]]; then exit 43; fi
echo $directories

for bench_name in $directories; do
    echo "[$(date +"%H:%M:%S")] Running: ${bench_name}"

    # Create the directory for the results and clean it if already exist
    mkdir -p ${RESULTS_DIR}/${bench_name}
    FILENAME=${RESULTS_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
    echo $FILENAME
    
    if [[ ${SEARCH} -eq 1 ]]; then
        baseline=$(cat ${FILENAME} | python -c 'import sys;  print(max([int(l.strip()) for l in  sys.stdin.readlines()]))')
        echo $baseline
        FILENAME=${RESULTS_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}_SEARCH.txt
        # continue
    fi

    if [[ $PREVIOUS_BENCH -eq 1 ]]; then
        if [[ $CURRENT_BENCH != $bench_name ]]; then
            echo "Previous benchmark, skipped"
            continue
        fi
    else
        if [[ $KEEP -eq 0 ]]; then
            echo "Do not keep, clean"
            touch ${FILENAME}
            > ${FILENAME}

            # if [[ ${SEARCH} -eq 1 ]]; then
            #     echo "# Baseline ${baseline}, target slowdown ${TARGET_SLOWDOWN}" > ${FILENAME}
            #     echo "rep,apu_bandwidth,fpga_bandwidth,rpu_bandwidth,time,in_target,slowdown" >> ${FILENAME}
            # fi

            rep=0
        else
            if [[ ${SEARCH} -eq 1 ]]; then
                if [[ -f ${FILENAME} ]]; then
                    echo "EXISTING"
                    continue
                fi
                rep=0
            else
                rep=$(wc -l ${FILENAME} | awk '{print $1}')
            fi
        fi
        if [[ ${SEARCH} -eq 1 ]]; then
            echo "# Baseline ${baseline}, target slowdown ${TARGET_SLOWDOWN}" > ${FILENAME}
            echo "it,rep,bandwidth,time,in_target,slowdown" >> ${FILENAME}
            found_target_bandwidth=0
        else
            found_target_bandwidth=1
        fi
        
    fi

    echo "${bench_name} KEEP=${KEEP} ${rep}"
    # break

    # Check if the benchmark is in the ignore list
    echo "[$(date +"%H:%M:%S")] Get Ignored list"
    timeout -s 2 5m ssh root@${IP} grep -q "${bench_name}" ${TACLE_EXP_PATH}/${core}_ignore.txt
    IGNORE=$?
    if [[ $IGNORE -eq 128 ]] || [[ $IGNORE -eq 255 ]]; then exit 43; fi
    
    if [[ $IGNORE -eq 0 ]]; then
        for ((; rep<${REPETITIONS}; rep++)); do
            if [[ ${SAVE} -eq 1 ]]; then
                echo "0" >> $FILENAME
            fi
            echo "TIME: 0\n (skipped)\n"
        done
        echo "IGNORED"
        continue
    fi
    echo "NOT IGNORED"


    CURRENT_BENCH=$bench_name
    

    for ((; ! (rep >= ${REPETITIONS} && found_target_bandwidth); rep++)); do #rep<${REPETITIONS}

        if [[ ${SEARCH} -eq 1 ]]; then

            if [[ $PREVIOUS_BENCH -eq 0 ]]; then
                if [[ $rep -eq 0 ]]; then
                    LAST_BANDWIDTH=0
                    HIGHER_BOUND_BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH
                    BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH
                    LOWER_BOUND_BANDWIDTH=0

                    # BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH
                    # LAST_BANDWIDTH=$BOARD_MAX_APU_BANDWIDTH
                    last_slowdown=$TARGET_SLOWDOWN

                else

                    if [[ $it_under_target -eq 0 ]]; then
                        TMP_BANDWIDTH=`echo "( ${BANDWIDTH} + ${LOWER_BOUND_BANDWIDTH} ) * .5" | bc -l`
                        HIGHER_BOUND_BANDWIDTH=$BANDWIDTH
                        BANDWIDTH=$TMP_BANDWIDTH
                    else
                        TMP_BANDWIDTH=`echo "( ${BANDWIDTH} + ${HIGHER_BOUND_BANDWIDTH} ) * .5" | bc -l`
                        LOWER_BOUND_BANDWIDTH=$BANDWIDTH
                        BANDWIDTH=$TMP_BANDWIDTH
                    fi

                fi 
            fi

            echo "[$(date +"%H:%M:%S")] APPLYING TEMP REGULATION"
            timeout -s 2 5m ssh root@${IP} "bash ${BOARD_UTILITY_DIR}/apply_temp_reg.sh -B ${BANDWIDTH} -r -f -a"

            if [[ $? -ne 0 ]]; then exit 43; fi
            # printf "TIME: %d\n" ${time}

            it_under_target=1;

            if [[ $PREVIOUS_BENCH -eq 0 ]]; then
                it=0; 
                slowdowns_list=""
            fi

            for ((; it<${SEARCH_ITERS}; it++)); do

                SECONDS=0

                if [[ -z $timeout_s ]]; then
                    timeout_s=$TIMEOUT_SECONDS
                fi
                echo "Timeout: ${timeout_s}"

                save_on_file

                echo "[$(date +"%H:%M:%S")] Run benchmark on board"
                time=`timeout -s 2 ${timeout_s}s ssh root@${IP} "bash ${TACLE_EXP_PATH}/single_taclebench.sh -c ${core} -b ${bench_name}"`
                if [[ $? -ne 0 ]]; then exit 43; fi

                slowdown=`echo " $time/$baseline" | bc -l`
                slowdowns_list="$slowdowns_list;$slowdown"
                # echo "SLOWDOWN: $slowdown"
                in_target=`echo "$slowdown < $TARGET_SLOWDOWN" | bc -l`
                # bw_ratio=`echo "$TARGET_SLOWDOWN / ( ${slowdown} + ${last_slowdown} )" | bc -l`
                # echo "RATIO: $bw_ratio"

                # echo "BELOW_TARGET_SLOWDOWN: ${in_target}" 
                printf "%d,%d,%.10f,%d,%d,%.10f\n" ${rep} ${it} ${BANDWIDTH} ${time} ${in_target} ${slowdown}

                if [[ ${SAVE} -eq 1 ]]; then
                    echo "SAVING"
                    printf "%d,%d,%.10f,%d,%d,%.10f\n" ${rep} ${it} ${BANDWIDTH} ${time} ${in_target} ${slowdown} >> $FILENAME
                fi

                if [[ $in_target -eq 0 ]]; then
                    # LAST_BANDWIDTH=0
                    it_under_target=0
                    if [[ $rep -ne 0 ]]; then
                        break;
                    fi
                fi

                timeout_s=`echo "( 2 * ${SECONDS})" | bc`
        
                if [[ `echo "${timeout_s} < 20" | bc` -eq 1 ]]; then
                    echo "Timeout prechange: ${timeout_s}"
                    timeout_s=20
                elif [[ `echo "${timeout_s} > ${TIMEOUT_SECONDS}" | bc` -eq 1 ]]; then
                    echo "Timeout prechange: ${timeout_s}"
                    timeout_s=$TIMEOUT_SECONDS
                fi
            done

            if [[ $it_under_target -eq 1 ]]; then
                found_target_bandwidth=1
                avg_slowdown=`echo "$slowdowns_list" | python3 -c "from statistics import mean; print(mean([float(v) for v in input().split(';') if v]))"`
                if [[ `echo "$avg_slowdown > ($TARGET_SLOWDOWN - 0.01)" | bc` -eq 1 ]]; then
                    echo "CLOSE ENOUGH, break"
                    break
                fi
            fi
        else
            SECONDS=0
            if [[ -z $timeout_s ]]; then
                timeout_s=$TIMEOUT_SECONDS
            fi
            echo "Timeout: ${timeout_s}"

            save_on_file
            echo "[$(date +"%H:%M:%S")] Run benchmark on board"
            time=`timeout -s 2 ${timeout_s}s ssh root@${IP} "bash ${TACLE_EXP_PATH}/single_taclebench.sh -c ${core} -b ${bench_name}"`
            if [[ $? -ne 0 ]]; then exit 43; fi

            printf "%d\n" ${time}

            if [[ ${SAVE} -eq 1 ]]; then
                printf "%d\n" ${time} >> $FILENAME
            fi

            timeout_s=`echo "( 2 * ${SECONDS})" | bc`
            
            if [[ `echo "${timeout_s} < 20" | bc` -eq 1 ]]; then
                echo "Timeout prechange: ${timeout_s}"
                timeout_s=20
            elif [[ `echo "${timeout_s} > ${TIMEOUT_SECONDS}" | bc` -eq 1 ]]; then
                echo "Timeout prechange: ${timeout_s}"
                timeout_s=$TIMEOUT_SECONDS
            fi
        fi

        # Save Results
        # if [[ ${SAVE} -eq 1 ]]; then
        #     if [[ ${SEARCH} -eq 0 ]]; then
        #         printf "%d\n" ${time} >> $FILENAME
        #     else
        #         printf "%d,%.10f,%.10f,%.10f,%d,%d,%.10f\n" ${rep} ${APU_BANDWIDTH} ${FPGA_BANDWIDTH} ${RPU_BANDWIDTH} ${time} ${in_target} ${slowdown} >> $FILENAME
        #     fi
        # fi

        
        PREVIOUS_BENCH=0
    done

    unset timeout_s
done

## STOP TEST
# Disable Bandwidth regulation
echo "Stopping bandwidth regulation"
ssh root@${IP} "/root/jailhouse/tools/jailhouse qos disable"
# Disable Omnivisor
echo "Stopping Omnivisor"
#ssh root@${IP} "/root/jailhouse/tools/jailhouse disable" # > /dev/null 2>&1
echo "/root/jailhouse/tools/jailhouse disable" > ${SERIAL_PORT}
# Disable Disturbs
if [[ $DISTURB -eq 1 ]]; then
    # Stop APU membomb
    echo "Stopping APU membomb"
    echo "killall bandwidth" > ${SERIAL_PORT}

    # Stop RPU1 membomb
    echo "Stopping RPU1 membomb"
    echo "echo stop > /sys/class/remoteproc/remoteproc1/state" > ${SERIAL_PORT}

    # Stop FPGA membomb
    echo "Stopping FPGA Traffic Generators"
    echo "devmem ${TRAFFIC_GENERATOR_1} 64 0" > ${SERIAL_PORT}
    echo "devmem ${TRAFFIC_GENERATOR_2} 64 0" > ${SERIAL_PORT}
    echo "devmem ${TRAFFIC_GENERATOR_3} 64 0" > ${SERIAL_PORT}
fi

# Print Results
if [[ ${PRINT} -eq 1 ]]; then
    echo Print to implement ...
fi
