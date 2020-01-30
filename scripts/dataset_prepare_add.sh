#/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $(basename $0) PRODUCT FOLDER [PREPARE_SCRIPT]"
	exit 1
fi

PRODUCT=$1
FOLDER=$2
PREPARE=${3:-"/opt/odc/utils/ls_usgs_prepare.py"}
YAML_LIST_FILE="/tmp/yaml_list_file.txt"

DATASET_PREPARE_SCRIPT="./dataset_prepare.sh"
DATASET_ADD_SCRIPT="./dataset_add.sh"


$DATASET_PREPARE_SCRIPT $FOLDER $YAML_LIST_FILE $PREPARE
$DATASET_ADD_SCRIPT $PRODUCT $YAML_LIST_FILE


