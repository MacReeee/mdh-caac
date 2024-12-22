#! /bin/bash
./network.sh down
./network.sh up

./network.sh createChannel -c gatewaychannel
./network.sh createChannel -c domain1channel
./network.sh createChannel -c domain2channel./net