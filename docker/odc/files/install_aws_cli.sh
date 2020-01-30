#!/bin/bash
# Install AWS CLI

echo "Creating $HOME/S3_scripts and downloading ODC S3 scripts"
mkdir -p $HOME/Datacube/S3_scripts
cd $HOME/Datacube/S3_scripts
wget https://raw.githubusercontent.com/opendatacube/datacube-core/develop/datacube/index/hl.py
wget https://raw.githubusercontent.com/opendatacube/datacube-dataset-config/master/scripts/index_from_s3_bucket.py
wget https://raw.githubusercontent.com/opendatacube/datacube-core/develop/docs/config_samples/dataset_types/ls_usgs.yaml

echo "Installing software"
sudo apt-get update 
sudo apt-get install -y --no-install-recommends awscli ca-certificates
sudo pip3 install boto3 ruamel.yaml
sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf $HOME/.cache/pip

aws configure

export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
echo "export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt" >> $HOME/.bashrc

echo "For S3 indexing example, go to https://datacube-core.readthedocs.io/en/latest/ops/indexing.html"
echo

