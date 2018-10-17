#/bin/sh

command_exists () {
    type $1 >/dev/null 2>&1;
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

# identify CPU architecture
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

# check if bash interpreter exists
if !(command_exists bash); then
    if !(command_exists file); then
        arch=$(test_arch)
    else
        arch=$(get_arch)
    fi

    compiled_bash="${arch}-arch/bash"
    if [[ ! -f "$compiled_bash" ]]; then
        printf "\033[31mError: Cross compiled bash binary not found.\033[m\n\n"
    fi
    # install cross compiled bash into system $PATH environment
    cp "$compiled_bash" /bin/bash

    if !(command_exists bash); then
        printf "\033[31mError: Cross compiled bash binary not correct.\033[m\n\n"
    fi
fi
