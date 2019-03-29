#!/bin/bash

# Make Bash intolerant to errors
set -o nounset
set -o errexit
set -o pipefail


# ===== Constants and functions


SOLR_DOWNLOAD_PATH="/tmp/solr.tgz"


RUNTIME_DEPENDENCIES="cgroup-tools procps"


function download_file() {
    local origin_url="$1"
    local destination_path="$2"
    local sha1_checksum="$3"

    wget --no-verbose "--output-document=${destination_path}" "${origin_url}"
    check_file_sha1_sum "${destination_path}" "${sha1_checksum}"
}


function check_file_sha1_sum() {
    local file_path="$1"
    local expected_sha1_checksum="$2"

    local actual_sha1_checksum="$(sha1sum "${file_path}" | awk '{ print $1 }')"
    if [[ "${expected_sha1_checksum}" != "${actual_sha1_checksum}" ]]; then
        echo "File '${file_path}' did not pass integrity check" >&2
        exit 1
    fi
}


function expand_tgz() {
    local compressed_file_path="$1"
    local destination_dir_path="$2"
    local extra_tar_args="${@:3}"

    tar \
        --extract \
        --directory "${destination_dir_path}" \
        --file "${compressed_file_path}" \
        ${extra_tar_args}
    rm "${compressed_file_path}"
}


function deploy_solr_distribution() {
    local mirror_url="$1"

    local solr_download_url="${mirror_url}/solr-${SOLR_VERSION}.tgz"
    download_file \
        "${solr_download_url}" \
        "${SOLR_DOWNLOAD_PATH}" \
        "${SOLR_SHA1_CHECKSUM}"

    mkdir --parents "${SOLR_DISTRIBUTION_PATH}"
    expand_tgz \
        "${SOLR_DOWNLOAD_PATH}" \
        "${SOLR_DISTRIBUTION_PATH}" \
        --strip-components=1
}


function configure_solr_home() {
    mkdir --parents "${SOLR_HOME_PATH}"
    cp \
        "${SOLR_DISTRIBUTION_PATH}/example/solr/collection1/conf/solrconfig.xml" \
        "${SOLR_DISTRIBUTION_PATH}/example/solr/solr.xml" \
        "${SOLR_HOME_PATH}"
    mkdir "${SOLR_HOME_PATH}/cores"

    mkdir --parents "${SOLR_INDICES_DIR_PATH}"
    chown "${SOLR_USER}" "${SOLR_INDICES_DIR_PATH}"
}


function configure_jetty_home() {
    mkdir --parents "${JETTY_HOME_PATH}"
    cp \
        --recursive \
        "${SOLR_DISTRIBUTION_PATH}/example/contexts" \
        "${SOLR_DISTRIBUTION_PATH}/example/etc" \
        "${SOLR_DISTRIBUTION_PATH}/example/lib" \
        "${SOLR_DISTRIBUTION_PATH}/example/webapps" \
        "${JETTY_HOME_PATH}"

    local solr_temp_dir_path="${JETTY_HOME_PATH}/solr-webapp"
    mkdir "${solr_temp_dir_path}"
    chown "${SOLR_USER}" "${solr_temp_dir_path}"
}


function install_deb_packages() {
    local package_specs="${@}"

    apt-get update --option "Acquire::Retries=3" --quiet=2
    apt-get install \
        --option "Acquire::Retries=3" \
        --no-install-recommends \
        --assume-yes \
        --quiet=2 \
        ${@}
    rm -rf /var/lib/apt/lists/*
}


# ===== Main


adduser --system "${SOLR_USER}"
deploy_solr_distribution "$1"
configure_solr_home
configure_jetty_home
install_deb_packages ${RUNTIME_DEPENDENCIES}
