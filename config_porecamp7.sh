#!/bin/bash

export THREADS=23
export TACC_ALBACORE="${CONTAINER_ROOT}/${TACC_ALBACORE_1_1_1}"
export TACC_ALBACORE_VERS=1_1_1
export ALBA_CONFIG="/opt/albacore/r95_450bps_linear.cfg"
export ALBA_BATCH=4000
export ALBA_BARCODE=""
export ALBA_FORMAT="fastq,fast5"
export ALBA_RECURSIVE="--recursive"
export ALBA_EXTRA_OPTS=""

# Time budget for 60,000 5000bp fast5 files
export RUNTIME_PER_UNIT=1
