#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $(basename $0) FOLDER YAML_LIST_FILE [PREPARE_SCRIPT]"
	exit 1
fi

FOLDER=$1
YAML_LIST_FILE=$2
PREPARE=${3:-"/opt/odc/utils/ls_usgs_prepare.py"}

if [ -f $YAML_LIST_FILE ]; then
    echo "File $YAML_LIST_FILE alread exists. Appending new lines."
fi

find $FOLDER -name "*.tar.gz" -print0 |
	while IFS= read -r -d $'\0' f; do
		FILE_DEST=$(dirname $f)
		DESTFOLDER=${f%.tar.gz}
		FILENAME=$(basename $f)
		YAMLFILE="${FILENAME%.tar.gz}.yaml"
		if [ ! -d $DESTFOLDER ]; then
			mkdir $DESTFOLDER
			tar -C $DESTFOLDER -xvzf $f
		fi
		python3 $PREPARE --output $DESTFOLDER/$YAMLFILE $DESTFOLDER
        echo "$DESTFOLDER/$YAMLFILE" >> $YAML_LIST_FILE
	done
