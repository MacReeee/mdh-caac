#!/bin/bash

# import utils
. scripts/envVar.sh
. scripts/configUpdate.sh

# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"

  if [ $ORG -eq 1 ]; then
    HOST="peer0.org1.example.com"
    PORT=7051
  elif [ $ORG -eq 2 ]; then
    HOST="peer0.org2.example.com"
    PORT=9051
  elif [ $ORG -eq 3 ]; then
    HOST="peer0.org3.example.com"
    PORT=11051
  elif [ $ORG -eq 4 ]; then
    HOST="peer0.org4.example.com"
    PORT=13051
  elif [ $ORG -eq 5 ]; then
    HOST="peer0.gateway1.example.com"
    PORT=7151
  elif [ $ORG -eq 6 ]; then
    HOST="peer0.gateway2.example.com"
    PORT=7251
  elif [ $ORG -eq 7 ]; then
    HOST="peer0.gateway3.example.com"
    PORT=7351
  elif [ $ORG -eq 8 ]; then
    HOST="peer0.gateway4.example.com"
    PORT=7451
  elif [ $ORG -eq 9 ]; then
    HOST="peer0.gateway5.example.com"
    PORT=7551
  elif [ $ORG -eq 10 ]; then
    HOST="peer0.gateway6.example.com"
    PORT=7651
  elif [ $ORG -eq 11 ]; then
    HOST="peer0.gateway7.example.com"
    PORT=7751
  elif [ $ORG -eq 12 ]; then
    HOST="peer0.gateway8.example.com"
    PORT=7851
  elif [ $ORG -eq 13 ]; then
    HOST="peer0.gateway9.example.com"
    PORT=7951
  elif [ $ORG -eq 14 ]; then
    HOST="peer0.gateway10.example.com"
    PORT=8051
  elif [ $ORG -eq 15 ]; then
    HOST="peer0.gateway11.example.com"
    PORT=8151
  elif [ $ORG -eq 16 ]; then
    HOST="peer0.gateway12.example.com"
    PORT=8251
  elif [ $ORG -eq 17 ]; then
    HOST="peer0.gateway13.example.com"
    PORT=8351
  elif [ $ORG -eq 18 ]; then
    HOST="peer0.gateway14.example.com"
    PORT=8451
  elif [ $ORG -eq 19 ]; then
    HOST="peer0.gateway15.example.com"
    PORT=8551
  elif [ $ORG -eq 20 ]; then
    HOST="peer0.gateway16.example.com"
    PORT=8651
  elif [ $ORG -eq 21 ]; then
    HOST="peer0.gateway17.example.com"
    PORT=8751
  elif [ $ORG -eq 22 ]; then
    HOST="peer0.gateway18.example.com"
    PORT=8851
  else
    errorln "Org${ORG} unknown"
  fi

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

ORG=$1
CHANNEL_NAME=$2
setGlobalsCLI $ORG

createAnchorPeerUpdate 

updateAnchorPeer