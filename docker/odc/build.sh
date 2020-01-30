#!/bin/bash

IMAGE="odc"
VERSION="1.7"



docker build "$@" -t ${IMAGE}:${VERSION} .

