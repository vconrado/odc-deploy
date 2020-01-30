#!/bin/bash

IMAGE="odc-jupyter"
VERSION="1.7"

docker build "$@" -t ${IMAGE}:${VERSION} .

