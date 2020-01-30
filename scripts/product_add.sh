#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) YAML_FILE"
	exit 1
fi

YAML_FILE=$1

datacube product add $YAML_FILE

