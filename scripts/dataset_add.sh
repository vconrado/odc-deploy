#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $(basename $0) PRODUCT YAML_LIST_FILE"
	exit 1
fi

PRODUCT=$1
YAML_LIST_FILE=$2

if [ ! -f "$YAML_LIST_FILE" ]; then
    echo "$YAML_LIST_FILE is not a valid file"
    exit 1
fi

while read -r YAMLFILE
    datacube -v dataset add -p $PRODUCT $YAMLFILE
done < "$YAML_LIST_FILE"

