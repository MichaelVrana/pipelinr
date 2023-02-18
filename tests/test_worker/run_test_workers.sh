#!/bin/bash

# This script runs the SSH worker containers and creates an SSH config together with GNU Parallel SSH login file
# You can adjust the number of SSH workers in the docker-compose.yml file (replicas field)

docker-compose up -d --build

hostnames=$(docker network inspect test_worker_default | jq '.[0].Containers[] | "\(.Name) \(.IPv4Address)"' | sed -r 's/"|(\/.*)//g')

echo "Host *
    User worker
    IdentityFile $(pwd)/id_rsa_test
    StrictHostKeyChecking=no
    UserKnownHostsFile=/dev/null
    LogLevel ERROR

$(sed -r 's/(.*) (.*)/Host \1\n    Hostname \2\n/g' <<< $hostnames)" > ssh.config

sed -r 's/(.*) .*/1\/ \1/g' <<< $hostnames > nodefile
