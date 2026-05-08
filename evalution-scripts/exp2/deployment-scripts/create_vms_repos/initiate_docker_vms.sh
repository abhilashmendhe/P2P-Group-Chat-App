#!/bin/bash

if [[ `docker ps 2> /dev/null; echo $?` == 1 ]]; then
    echo "Docker is not running."
    exit 1
fi

echo "Docker is running"

NUM_VMS=2
PASS="Asimov@123"
for ((i=1; i<=$NUM_VMS; i++));do 
    docker run -dt --memory=1g --cpus=0.5 --name peer$i \
  -v $PWD:/root/run_scripts \
  -w /root/run_scripts/vms \
  peers:01 \
  bash -c "/root/run_scripts/_1_repo_init/target/release/repo_init peer$i && 
    echo 'root:$PASS | chpasswd' &&
    service ssh restart && 
    tail -f /dev/null"
done
