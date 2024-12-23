#!/bin/bash

# imports  
. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {
	set -x
	# 根据不同channel使用不同的profile
	if [ "$CHANNEL_NAME" == "gatewaychannel" ]; then
		configtxgen -profile gatewaychannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	elif [ "$CHANNEL_NAME" == "domain1channel" ]; then
		configtxgen -profile domain1channel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	elif [ "$CHANNEL_NAME" == "domain2channel" ]; then
		configtxgen -profile domain2channel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	else
		errorln "Unknown channel name: ${CHANNEL_NAME}"
		exit 1
	fi
	res=$?
	{ set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	# 使用GatewayOrg创建channel
  if [ "$CHANNEL_NAME" == "gatewaychannel" ]; then
    setGlobals 5  # 使用Gateway1Org创建gatewaychannel
	elif [ "$CHANNEL_NAME" == "domain2channel" ]; then
    setGlobals 6  # 使用Gateway2Org创建domain2
  elif [ "$CHANNEL_NAME" == "domain1channel" ]; then
    setGlobals 5  # 使用Gateway1Org创建其他channel
  fi

	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BLOCKFILE --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  FABRIC_CFG_PATH=$PWD/../config/
  ORG=$1
  setGlobals $ORG

  # 调试信息
  echo "Joining channel with following config:"
  echo "CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"
  echo "CORE_PEER_TLS_ROOTCERT_FILE: $CORE_PEER_TLS_ROOTCERT_FILE"

	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  docker exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channeltx
infoln "Generating channel create transaction '${CHANNEL_NAME}.tx'"
createChannelTx

FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel
successln "Channel '$CHANNEL_NAME' created"

## 根据不同的channel加入不同的组织
if [ "$CHANNEL_NAME" == "gatewaychannel" ]; then
    infoln "Joining gateway1 peers to the channel..."
    joinChannel 5
    infoln "Joining gateway2 peers to the channel..."
    joinChannel 6
    infoln "Setting anchor peer for gateway1 org..."
    setAnchorPeer 5
    infoln "Setting anchor peer for gateway2 org..."
    setAnchorPeer 6
elif [ "$CHANNEL_NAME" == "domain1channel" ]; then
    infoln "Joining org1 peer to the channel..."
    joinChannel 1
    infoln "Joining org2 peer to the channel..."
    joinChannel 2
    infoln "Joining gateway1 peer to the channel..."
    joinChannel 5
    infoln "Setting anchor peer for org1..."
    setAnchorPeer 1
    infoln "Setting anchor peer for org2..."
    setAnchorPeer 2
    infoln "Setting anchor peer for gateway1 org..."
    setAnchorPeer 5
elif [ "$CHANNEL_NAME" == "domain2channel" ]; then
    infoln "Joining org3 peer to the channel..."
    joinChannel 3
    infoln "Joining org4 peer to the channel..."
    joinChannel 4
    infoln "Joining gateway2 peer to the channel..."
    joinChannel 6
    infoln "Setting anchor peer for org3..."
    setAnchorPeer 3
    infoln "Setting anchor peer for org4..."
    setAnchorPeer 4
    infoln "Setting anchor peer for gateway2 org..."
    setAnchorPeer 6
fi

successln "Channel '$CHANNEL_NAME' joined"