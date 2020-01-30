#!/bin/bash


if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) FILE.yaml [CORES]"
fi

FILE=$1
CORES=${2-1}
FILE=$(realpath $FILE)

if [ ! -f $FILE ]; then
	echo "File '$FILE' not found."
	exit 1
fi

time datacube ingest -c $FILE --executor multiproc $CORES  2>&1
