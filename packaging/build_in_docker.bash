#!/bin/bash

set -o errexit

docker build -t sasc_build docker_build_env

docker run -ti -v `pwd`:/tmp/packaging sasc_build bash -c 'cd /tmp/packaging && ./build_package.sh'
