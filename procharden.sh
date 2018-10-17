#!/bin/bash

# global values
have_readelf=0
have_cut=0
have_awk=0
have_sed=0
have_wc=0
have_file=0

indexOfPid () {
    # if 'ps' or 'ps -ef' running output is aligned, calucate pid number position using the following method.
    # take a example like this:
    # UID        PID  PPID  C STIME TTY          TIME CMD
    # root         1     0  0 Oct12 ?        00:00:03 /sbin/init

    #local i
    #for ((i=0; i<${#1}; i++))
    #do
        # determinate if the 3 continuous characters is 'PID'
        #if [ "${1:i:3}" == "PID" ]; then
            # print last character's postion of 'PID'
            #echo $(($i+2))
            #return 0
        #fi
    #done
    #return -1
    
    # if 'ps' or 'ps -ef' running output is not aligned, calucate pid number position using the following method instead.
    # take a example like this:
    # PID   USER      TIME   COMMAND
    #     1 root        0:00 init
    local count=0
    for item in ${1}
    do
        if [[ "$item" == "PID" ]]; then
            echo $count
            return 0
        fi
        count=$(($count+1))
    done

    return -1
}

getPidNum () {
    # if 'ps' or 'ps -ef' running output is aligned, calucate pid number position using the following method.
    # take a example like this:
    # UID        PID  PPID  C STIME TTY          TIME CMD
    # root         1     0  0 Oct12 ?        00:00:03 /sbin/init

    #local i
    #end=$2
    #for ((i=${2}; i>0; i--))
    #do
        # determinate if the character is blank space
        #if [ "${1:i:1}" == " " ]; then
            #sindex=$(($i+1))
            #eindex=$(($end-$i))
            #pidstr="${1:sindex:eindex}"
            # print pid number
            #echo $pidstr
            #return 0
        #fi
    #done    
    #return -1
    
    # if 'ps' or 'ps -ef' running output is not aligned, calucate pid number position using the following method instead.
    # take a example like this:
    # PID   USER      TIME   COMMAND
    #     1 root        0:00 init
    index=0
    count=${2}
    for item in ${1}
    do
        if [[ $index -eq $count ]]; then
            echo $item
            return 0
        fi    
    index=$(($index+1))
    done
    
    return -1
}

getFilePath () {
    if [[ -f "/proc/$pid/exe" ]];then
        info=$(ls -l /proc/$pid/exe)
        # print absolute file path for the the given PID's process
        path=${info##*-> }
        echo $path
    fi
}

# check if command exists
command_exists () {
    type $1  > /dev/null 2>&1;
}

# pre-run ps command on host
ps_count () {
    num=0

    if [[ $have_wc -eq -1 ]]; then
	    num=$(ps -ef| wc -l | grep -Ev '(\[.*\])|(grep)|(procharden)')
    else
	# avoid subshell in bash script
	# https://www.tldp.org/LDP/abs/html/x17974.html
	# http://xstarcd.github.io/wiki/shell/exec_redirect.html
        exec 4<&1
	exec 1>hostprocs
	ps -ef | grep -Ev '(\[.*\])|(grep)|(ps)|(procharden)'
	while read line
        do
	    num=$((num+1))
        done < hostprocs
    fi

    exec 1<&4
    exec 4>&-
    #rm -f hostprocs
    # return value by calling `echo` bettween father and child process
    echo $num
}

# check user privileges
root_privs () {
    if [ $(id -u) -eq 0 ] ; then
        return 0
    else
        return 1
    fi
}

# get CPU architecture
get_arch () {
    if $(file /bin/busybox | grep -i 'MIPS' | grep -i 'MSB'); then
        echo 'mipsb'
    elif $(file /bin/busybox | grep -i 'MIPS' | grep -i 'LSB'); then
        echo 'mipsel'
    elif $(file /bin/busybox | grep 'ARM'); then
        echo 'armel'
    else
        echo 'unknown'
    fi
}
# test CPU architecture
test_arch () {
    if $( $(pwd)/mipsb-arch/readelf --help 1>/dev/null 2>&1 ); then
        echo "mipsb"
    elif $( $(pwd)/mipsel-arch/readelf --help 1>/dev/null 2>&1 ); then
        echo "mipsel"
    elif $( $(pwd)/armel-arch/readelf --help 1>/dev/null 2>&1 ); then
        echo "armel"
    else
        echo "unknown"
    fi
}

# firstly, ensure running user is root
if !(root_privs); then
    printf "\n\033[33mError: You are running 'procharden.sh' as an unprivileged user.\n"
    exit 1
fi

# secondly, check requisites
if !(command_exists readelf); then
    printf "\033[31mWarning: 'readelf' not found! It's required for most checks.\033[m\n\n"
    have_readelf=-1
fi

if !(command_exists cut); then
    printf "\033[31mWarning: 'cut' not found! It's required for most checks.\033[m\n\n"
    have_cut=-1
fi

if !(command_exists awk); then
    printf "\033[31mWarning: 'awk' not found! It's required for most checks.\033[m\n\n"
    have_awk=-1
fi

if !(command_exists sed); then
    printf "\033[31mWarning: 'sed' not found! It's required for most checks.\033[m\n\n"
    have_sed=-1
fi

if !(command_exists wc); then
    printf "\033[31mWarning: 'wc' not found! It's required for most checks.\033[m\n\n"
    have_wc=-1
fi

if !(command_exists file); then
    printf "\033[31mWarning: 'file' not found! It's required for most checks.\033[m\n\n"
    have_file=-1
fi

# the following commands must be existed 
if [[ $have_cut -eq -1 || $have_awk -eq -1 || $have_sed -eq -1 ]]; then
    exit 1
fi

# get CPU architecture 
if [[ $have_file -eq -1 ]]; then
    arch=$(get_arch) 
else
    arch=$(test_arch)
fi

# once architecture understood, export cross compiled toolkits directory into system PATH environment    
if [[ $arch == "mipsb" ]]; then
    export PATH=$PATH:"$(pwd)/mipsb-arch"
elif [[ $arch == "mipsel" ]]; then
    export PATH=$PATH:"$(pwd)/mipsel-arch"
elif [[ $arch == "armel" ]]; then
    export PATH=$PATH:"$(pwd)/armel-arch"
else
    printf "\033[31mError: Host CPU architecture not understood.\033[m\n\n"
    exit 1
fi

# counting process on host
if [[ $(ps_count) -le 2 ]]; then
    printf "\033[31mError: process numbers is too small, 'ps' command is invalid.\033[m\n\n"
    exit 1
fi

if [ ! -f "hostprocs" ];then
    ps -ef | grep -Ev '(\[.*\])|(grep)|(ps)|(procharden)' > hostprocs
fi

pos=-1
cat hostprocs | while read line
do
    if [[ $pos -eq -1 ]];then
        pos=$(indexOfPid "$line")
    else
        pid=$(getPidNum "$line" $pos)
        #path=$(getFilePath $pid)
        # execute security audit for those process's binary 
        #checksec --file $path
        # execute security audit for those process's binary and loaded libraries
        printf "\033[34mPerform GCC Hardened options audit for process of 'pid=$pid'\033[m\n\n"
        printf "\33[34m/*******************************************************************************************************************************************/\033[m\n\n"
        # Note that shell interpreter must be 'bash' rather 'sh', or error occurs
        bash checksec --proc-libs $pid 
    fi
done

# do some clean work
rm -f hostprocs