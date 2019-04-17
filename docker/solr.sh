#!/bin/bash

# Make Bash intolerant to errors
set -o nounset
set -o errexit
set -o pipefail


# ===== Configuration


JVM_MIN_HEAP_RATIO="0.5"
JVM_MAX_HEAP_RATIO="0.95"


# ===== Constants and functions


function multiply() {
    # Multiply two numbers. Easy, right? Except awk can sometimes be 32 bit,
    # making it only go up to about 2GB of bytes, bash can only multiply ints,
    # and bc can neither convert floats to ints nor strip newlines.
    local x="$1"
    local y="$2"
    local result=$(echo "$x * $y" | bc | tr -d '\n')
    echo -n ${result%.*}
}


function get_container_memory_bytes() {
    cgget -n --values-only --variable memory.limit_in_bytes /
}


function get_host_memory_bytes() {
    free --bytes --total | tail --lines=1 | awk '{ print $2 }'
}


function is_container_memory_limited() {
    (( $(get_container_memory_bytes) < $(get_host_memory_bytes) ))
}


function get_jvm_memory_cli_args() {
    local cli_args

    if is_container_memory_limited; then
        local container_memory_bytes="$(get_container_memory_bytes)"
        local min_heap_bytes="$(multiply "${container_memory_bytes}" "${JVM_MIN_HEAP_RATIO}" )"
        local max_heap_bytes="$(multiply "${container_memory_bytes}" "${JVM_MAX_HEAP_RATIO}" )"
        cli_args="-Xms${min_heap_bytes} -Xmx${max_heap_bytes}"
    else
        cli_args=""
    fi

    echo "${cli_args}"
}


# ===== Main


JAVA_EXTRA_ARGS="${@:1} $(get_jvm_memory_cli_args)"


cd "${JETTY_HOME_PATH}"
exec java \
    -server \
    -Djava.net.preferIPv4Stack=true \
    -Djetty.home="${JETTY_HOME_PATH}" \
    -Dsolr.solr.home="${SOLR_HOME_PATH}" \
    -Dsolr.data.dir="${SOLR_INDICES_DIR_PATH}" \
    ${JAVA_EXTRA_ARGS} \
    -jar "${SOLR_DISTRIBUTION_PATH}/example/start.jar"
