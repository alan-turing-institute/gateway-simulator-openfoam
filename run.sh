#!/bin/bash

ssh-keygen -t rsa -f simulator_key -C "simulator key" -N ''
export SIMULATOR_KEY_PUBLIC=$(cat simulator_key.pub)

docker build -t simulator_base .

docker run -d --privileged -e AUTHORIZED_KEY="$SIMULATOR_KEY_PUBLIC" -p 10022:22 simulator_base


ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i simulator_key -p 10022 testuser@localhost
