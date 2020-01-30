#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $(basename $0) FOLDER PRODUCT"
	exit 1
fi

FOLDER=$1
PRODUCT=$2
PREPARE="/opt/odc/utils/ls_usgs_prepare.py"

find $FOLDER -name "*.tar.gz" -print0 |
	while IFS= read -r -d $'\0' f; do
		FILE_DEST=$(dirname $f)
		DESTFOLDER=${f%.tar.gz}
		FILENAME=$(basename $f)
		YAMLFILE="${FILENAME%.tar.gz}.yaml"
		if [ ! -d $DESTFOLDER ]; then
			mkdir $DESTFOLDER
			tar -C $DESTFOLDER -xvzf $f
			python3 $PREPARE --output $DESTFOLDER/$YAMLFILE $DESTFOLDER
			datacube -v dataset add -p $PRODUCT $DESTFOLDER/$YAMLFILE
		else
		
			echo "Skiping file $FILENAME. Folder $DESTFOLDER already exists."
		fi
	done
