#!/bin/bash

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export PEER0_ORG4_CA=${PWD}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export PEER0_GATEWAY1_CA=${PWD}/organizations/peerOrganizations/gateway1.example.com/peers/peer0.gateway1.example.com/tls/ca.crt
export PEER0_GATEWAY2_CA=${PWD}/organizations/peerOrganizations/gateway2.example.com/peers/peer0.gateway2.example.com/tls/ca.crt
export PEER0_GATEWAY3_CA=${PWD}/organizations/peerOrganizations/gateway3.example.com/peers/peer0.gateway3.example.com/tls/ca.crt
export PEER0_GATEWAY4_CA=${PWD}/organizations/peerOrganizations/gateway4.example.com/peers/peer0.gateway4.example.com/tls/ca.crt
export PEER0_GATEWAY5_CA=${PWD}/organizations/peerOrganizations/gateway5.example.com/peers/peer0.gateway5.example.com/tls/ca.crt
export PEER0_GATEWAY6_CA=${PWD}/organizations/peerOrganizations/gateway6.example.com/peers/peer0.gateway6.example.com/tls/ca.crt
export PEER0_GATEWAY7_CA=${PWD}/organizations/peerOrganizations/gateway7.example.com/peers/peer0.gateway7.example.com/tls/ca.crt
export PEER0_GATEWAY8_CA=${PWD}/organizations/peerOrganizations/gateway8.example.com/peers/peer0.gateway8.example.com/tls/ca.crt
export PEER0_GATEWAY9_CA=${PWD}/organizations/peerOrganizations/gateway9.example.com/peers/peer0.gateway9.example.com/tls/ca.crt
export PEER0_GATEWAY10_CA=${PWD}/organizations/peerOrganizations/gateway10.example.com/peers/peer0.gateway10.example.com/tls/ca.crt
export PEER0_GATEWAY11_CA=${PWD}/organizations/peerOrganizations/gateway11.example.com/peers/peer0.gateway11.example.com/tls/ca.crt
export PEER0_GATEWAY12_CA=${PWD}/organizations/peerOrganizations/gateway12.example.com/peers/peer0.gateway12.example.com/tls/ca.crt
export PEER0_GATEWAY13_CA=${PWD}/organizations/peerOrganizations/gateway13.example.com/peers/peer0.gateway13.example.com/tls/ca.crt
export PEER0_GATEWAY14_CA=${PWD}/organizations/peerOrganizations/gateway14.example.com/peers/peer0.gateway14.example.com/tls/ca.crt
export PEER0_GATEWAY15_CA=${PWD}/organizations/peerOrganizations/gateway15.example.com/peers/peer0.gateway15.example.com/tls/ca.crt
export PEER0_GATEWAY16_CA=${PWD}/organizations/peerOrganizations/gateway16.example.com/peers/peer0.gateway16.example.com/tls/ca.crt
export PEER0_GATEWAY17_CA=${PWD}/organizations/peerOrganizations/gateway17.example.com/peers/peer0.gateway17.example.com/tls/ca.crt
export PEER0_GATEWAY18_CA=${PWD}/organizations/peerOrganizations/gateway18.example.com/peers/peer0.gateway18.example.com/tls/ca.crt


# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  elif [ $USING_ORG -eq 4 ]; then
    export CORE_PEER_LOCALMSPID="Org4MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG4_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
    export CORE_PEER_ADDRESS=localhost:13051
  elif [ $USING_ORG -eq 5 ]; then # Gateway1Org 使用数字5
    export CORE_PEER_LOCALMSPID="Gateway1OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway1.example.com/users/Admin@gateway1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7151
  elif [ $USING_ORG -eq 6 ]; then # Gateway2Org 使用数字6
    export CORE_PEER_LOCALMSPID="Gateway2OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway2.example.com/users/Admin@gateway2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7251
  elif [ $USING_ORG -eq 7 ]; then # Gateway3Org 使用数字7
    export CORE_PEER_LOCALMSPID="Gateway3OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway3.example.com/users/Admin@gateway3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7351
  elif [ $USING_ORG -eq 8 ]; then # Gateway4Org 使用数字8
    export CORE_PEER_LOCALMSPID="Gateway4OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY4_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway4.example.com/users/Admin@gateway4.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7451
  elif [ $USING_ORG -eq 9 ]; then # Gateway5Org 使用数字9
    export CORE_PEER_LOCALMSPID="Gateway5OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY5_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway5.example.com/users/Admin@gateway5.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7551
  elif [ $USING_ORG -eq 10 ]; then # Gateway6Org 使用数字10
    export CORE_PEER_LOCALMSPID="Gateway6OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY6_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway6.example.com/users/Admin@gateway6.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7651
  elif [ $USING_ORG -eq 11 ]; then # Gateway7Org 使用数字11
    export CORE_PEER_LOCALMSPID="Gateway7OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY7_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway7.example.com/users/Admin@gateway7.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7751
  elif [ $USING_ORG -eq 12 ]; then # Gateway8Org 使用数字12
    export CORE_PEER_LOCALMSPID="Gateway8OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY8_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway8.example.com/users/Admin@gateway8.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7851
  elif [ $USING_ORG -eq 13 ]; then # Gateway9Org 使用数字13
    export CORE_PEER_LOCALMSPID="Gateway9OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY9_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway9.example.com/users/Admin@gateway9.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7951
  elif [ $USING_ORG -eq 14 ]; then # Gateway10Org 使用数字14
    export CORE_PEER_LOCALMSPID="Gateway10OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY10_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway10.example.com/users/Admin@gateway10.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
  elif [ $USING_ORG -eq 15 ]; then # Gateway11Org 使用数字15
    export CORE_PEER_LOCALMSPID="Gateway11OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY11_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway11.example.com/users/Admin@gateway11.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8151
  elif [ $USING_ORG -eq 16 ]; then # Gateway12Org 使用数字16
    export CORE_PEER_LOCALMSPID="Gateway12OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY12_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway12.example.com/users/Admin@gateway12.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8251
  elif [ $USING_ORG -eq 17 ]; then # Gateway13Org 使用数字17
    export CORE_PEER_LOCALMSPID="Gateway13OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY13_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway13.example.com/users/Admin@gateway13.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8351
  elif [ $USING_ORG -eq 18 ]; then # Gateway14Org 使用数字18
    export CORE_PEER_LOCALMSPID="Gateway14OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY14_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway14.example.com/users/Admin@gateway14.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8451
  elif [ $USING_ORG -eq 19 ]; then # Gateway15Org 使用数字19
    export CORE_PEER_LOCALMSPID="Gateway15OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY15_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway15.example.com/users/Admin@gateway15.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8551
  elif [ $USING_ORG -eq 20 ]; then # Gateway16Org 使用数字20
    export CORE_PEER_LOCALMSPID="Gateway16OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY16_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway16.example.com/users/Admin@gateway16.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8651
  elif [ $USING_ORG -eq 21 ]; then # Gateway17Org 使用数字21
    export CORE_PEER_LOCALMSPID="Gateway17OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY17_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway17.example.com/users/Admin@gateway17.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8751
  elif [ $USING_ORG -eq 22 ]; then # Gateway18Org 使用数字22
    export CORE_PEER_LOCALMSPID="Gateway18OrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_GATEWAY18_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway18.example.com/users/Admin@gateway18.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8851
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container 
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=peer0.org2.example.com:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_ADDRESS=peer0.org3.example.com:11051
  elif [ $USING_ORG -eq 4 ]; then
    export CORE_PEER_ADDRESS=peer0.org4.example.com:13051
  elif [ $USING_ORG -eq 5 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway1.example.com:7151
  elif [ $USING_ORG -eq 6 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway2.example.com:7251
  elif [ $USING_ORG -eq 7 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway3.example.com:7351
  elif [ $USING_ORG -eq 8 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway4.example.com:7451
  elif [ $USING_ORG -eq 9 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway5.example.com:7551
  elif [ $USING_ORG -eq 10 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway6.example.com:7651
  elif [ $USING_ORG -eq 11 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway7.example.com:7751
  elif [ $USING_ORG -eq 12 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway8.example.com:7851
  elif [ $USING_ORG -eq 13 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway9.example.com:7951
  elif [ $USING_ORG -eq 14 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway10.example.com:8051
  elif [ $USING_ORG -eq 15 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway11.example.com:8151
  elif [ $USING_ORG -eq 16 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway12.example.com:8251
  elif [ $USING_ORG -eq 17 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway13.example.com:8351
  elif [ $USING_ORG -eq 18 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway14.example.com:8451
  elif [ $USING_ORG -eq 19 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway15.example.com:8551
  elif [ $USING_ORG -eq 20 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway16.example.com:8651
  elif [ $USING_ORG -eq 21 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway17.example.com:8751
  elif [ $USING_ORG -eq 22 ]; then
    export CORE_PEER_ADDRESS=peer0.gateway18.example.com:8851
  else
    errorln "ORG Unknown"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER0_ORG$1_CA")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift by one to get to the next organization
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
