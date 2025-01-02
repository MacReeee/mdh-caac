#!/bin/bash

source scripts/utils.sh

CHANNEL_NAME=${1:-"mychannel"}
CC_NAME=${2}
CC_SRC_PATH=${3}
CC_SRC_LANGUAGE=${4}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"NA"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}

println "executing with the following"
println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"

FABRIC_CFG_PATH=$PWD/../config/

#User has not provided a name
if [ -z "$CC_NAME" ] || [ "$CC_NAME" = "NA" ]; then
  fatalln "No chaincode name was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a path
elif [ -z "$CC_SRC_PATH" ] || [ "$CC_SRC_PATH" = "NA" ]; then
  fatalln "No chaincode path was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a language
elif [ -z "$CC_SRC_LANGUAGE" ] || [ "$CC_SRC_LANGUAGE" = "NA" ]; then
  fatalln "No chaincode language was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

## Make sure that the path to the chaincode exists
elif [ ! -d "$CC_SRC_PATH" ]; then
  fatalln "Path to chaincode does not exist. Please provide different path."
fi

CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])

# do some language specific preparation to the chaincode before packaging
if [ "$CC_SRC_LANGUAGE" = "go" ]; then
  CC_RUNTIME_LANGUAGE=golang

  infoln "Vendoring Go dependencies at $CC_SRC_PATH"
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  successln "Finished vendoring Go dependencies"

elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
  CC_RUNTIME_LANGUAGE=java

  infoln "Compiling Java code..."
  pushd $CC_SRC_PATH
  ./gradlew installDist
  popd
  successln "Finished compiling Java code"
  CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME

elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
  CC_RUNTIME_LANGUAGE=node

elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
  CC_RUNTIME_LANGUAGE=node

  infoln "Compiling TypeScript code into JavaScript..."
  pushd $CC_SRC_PATH
  npm install
  npm run build
  popd
  successln "Finished compiling TypeScript code into JavaScript"

else
  fatalln "The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script. Supported chaincode languages are: go, java, javascript, and typescript"
  exit 1
fi

INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

# import utils
. scripts/envVar.sh

packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  if [ $res -ne 0 ]; then
    # 检查是否是"已安装"的错误
    if grep -q "chaincode already successfully installed" log.txt; then
      successln "Chaincode already installed on peer0.org${ORG}"
      return 0
    else
      fatalln "Chaincode installation on peer0.org${ORG} has failed"
    fi
  fi
  successln "Chaincode is installed on peer0.org${ORG}"
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.org${ORG} has failed"
  successln "Query installed successful on peer0.org${ORG} on channel"
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME'"
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  infoln "Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=0
    for var in "$@"; do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    infoln "Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID!"
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  # 修复版本：将所有参数正确排序，确保每个 --tlsRootCertFiles 后面跟着对应的证书路径
  # commitChaincodeDefinition 改为基于通道选择背书节点
  if [ "$CHANNEL_NAME" == "gatewaychannel" ]; then
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} \
        --peerAddresses localhost:7151 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway1.example.com/peers/peer0.gateway1.example.com/tls/ca.crt \
        --peerAddresses localhost:7251 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway2.example.com/peers/peer0.gateway2.example.com/tls/ca.crt \
        --peerAddresses localhost:7351 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway3.example.com/peers/peer0.gateway3.example.com/tls/ca.crt \
        --peerAddresses localhost:7451 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway4.example.com/peers/peer0.gateway4.example.com/tls/ca.crt \
        --peerAddresses localhost:7551 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway5.example.com/peers/peer0.gateway5.example.com/tls/ca.crt \
        --peerAddresses localhost:7651 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway6.example.com/peers/peer0.gateway6.example.com/tls/ca.crt \
        --peerAddresses localhost:7751 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway7.example.com/peers/peer0.gateway7.example.com/tls/ca.crt \
        --peerAddresses localhost:7851 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway8.example.com/peers/peer0.gateway8.example.com/tls/ca.crt \
        # --peerAddresses localhost:7951 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway9.example.com/peers/peer0.gateway9.example.com/tls/ca.crt \
        # --peerAddresses localhost:8051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway10.example.com/peers/peer0.gateway10.example.com/tls/ca.crt \
        # --peerAddresses localhost:8151 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway11.example.com/peers/peer0.gateway11.example.com/tls/ca.crt \
        # --peerAddresses localhost:8251 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway12.example.com/peers/peer0.gateway12.example.com/tls/ca.crt \
        # --peerAddresses localhost:8351 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway13.example.com/peers/peer0.gateway13.example.com/tls/ca.crt \
        # --peerAddresses localhost:8451 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway14.example.com/peers/peer0.gateway14.example.com/tls/ca.crt \
        # --peerAddresses localhost:8551 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway15.example.com/peers/peer0.gateway15.example.com/tls/ca.crt \
        # --peerAddresses localhost:8651 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway16.example.com/peers/peer0.gateway16.example.com/tls/ca.crt \
        # --peerAddresses localhost:8751 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway17.example.com/peers/peer0.gateway17.example.com/tls/ca.crt \
        # --peerAddresses localhost:8851 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway18.example.com/peers/peer0.gateway18.example.com/tls/ca.crt \
        ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG}

  elif [ "$CHANNEL_NAME" == "domain1channel" ]; then
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} \
        --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
        --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
        --peerAddresses localhost:7151 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway1.example.com/peers/peer0.gateway1.example.com/tls/ca.crt \
        ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG}

elif [ "$CHANNEL_NAME" == "domain2channel" ]; then
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} \
        --peerAddresses localhost:11051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
        --peerAddresses localhost:13051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt \
        --peerAddresses localhost:7251 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/gateway2.example.com/peers/peer0.gateway2.example.com/tls/ca.crt \
        ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG}
  fi
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  infoln "Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID!"
  fi
}

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
  infoln "invoke fcn call:${fcn_call}"
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS --isInit -c ${fcn_call} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  infoln "Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["queryAllCars"]}' >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID!"
  fi
}


## package the chaincode
packageChaincode

## Install chaincode on peers based on channel
if [ "$CHANNEL_NAME" == "gatewaychannel" ]; then
    infoln "Installing chaincode on gateway1 peer..."
    installChaincode 5
    infoln "Installing chaincode on gateway2 peer..."
    installChaincode 6
    infoln "Installing chaincode on gateway3 peer..."
    installChaincode 7
    infoln "Installing chaincode on gateway4 peer..."
    installChaincode 8
    infoln "Installing chaincode on gateway5 peer..."
    installChaincode 9
    infoln "Installing chaincode on gateway6 peer..."
    installChaincode 10
    infoln "Installing chaincode on gateway7 peer..."
    installChaincode 11
    infoln "Installing chaincode on gateway8 peer..."
    installChaincode 12
    # infoln "Installing chaincode on gateway9 peer..."
    # installChaincode 13
    # infoln "Installing chaincode on gateway10 peer..."
    # installChaincode 14
    # infoln "Installing chaincode on gateway11 peer..."
    # installChaincode 15
    # infoln "Installing chaincode on gateway12 peer..."
    # installChaincode 16
    # infoln "Installing chaincode on gateway13 peer..."
    # installChaincode 17
    # infoln "Installing chaincode on gateway14 peer..."
    # installChaincode 18
    # infoln "Installing chaincode on gateway15 peer..."
    # installChaincode 19
    # infoln "Installing chaincode on gateway16 peer..."
    # installChaincode 20
    # infoln "Installing chaincode on gateway17 peer..."
    # installChaincode 21
    # infoln "Installing chaincode on gateway18 peer..."
    # installChaincode 22
    
    queryInstalled 5
    
    approveForMyOrg 5
    approveForMyOrg 6
    approveForMyOrg 7
    approveForMyOrg 8
    approveForMyOrg 9
    approveForMyOrg 10
    approveForMyOrg 11
    approveForMyOrg 12
    # approveForMyOrg 13
    # approveForMyOrg 14
    # approveForMyOrg 15
    # approveForMyOrg 16
    # approveForMyOrg 17
    # approveForMyOrg 18
    # approveForMyOrg 19
    # approveForMyOrg 20
    # approveForMyOrg 21
    # approveForMyOrg 22
    
    # 更新所有组织的检查
    # checkCommitReadiness 5  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 6  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 7  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 8  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 9  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 10 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 11 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 12 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 13 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 14 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 15 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 16 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 17 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 18 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 19 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 20 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 21 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"
    # checkCommitReadiness 22 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true" "\"Gateway9OrgMSP\": true" "\"Gateway10OrgMSP\": true" "\"Gateway11OrgMSP\": true" "\"Gateway12OrgMSP\": true" "\"Gateway13OrgMSP\": true" "\"Gateway14OrgMSP\": true" "\"Gateway15OrgMSP\": true" "\"Gateway16OrgMSP\": true" "\"Gateway17OrgMSP\": true" "\"Gateway18OrgMSP\": true"

    checkCommitReadiness 5  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"
    checkCommitReadiness 6  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"
    checkCommitReadiness 7  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"
    checkCommitReadiness 8  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"
    checkCommitReadiness 9  "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"
    checkCommitReadiness 10 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"
    checkCommitReadiness 11 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"
    checkCommitReadiness 12 "\"Gateway1OrgMSP\": true" "\"Gateway2OrgMSP\": true" "\"Gateway3OrgMSP\": true" "\"Gateway4OrgMSP\": true" "\"Gateway5OrgMSP\": true" "\"Gateway6OrgMSP\": true" "\"Gateway7OrgMSP\": true" "\"Gateway8OrgMSP\": true"

    # 更新提交命令包含所有组织
    commitChaincodeDefinition 5 6 7 8 9 10 11 12

elif [ "$CHANNEL_NAME" == "domain1channel" ]; then
    infoln "Installing chaincode on org1 peer..."
    installChaincode 1
    infoln "Install chaincode on org2 peer..."
    installChaincode 2
    infoln "Install chaincode on gateway peer..."
    installChaincode 5

    queryInstalled 1

    approveForMyOrg 1
    approveForMyOrg 2
    approveForMyOrg 5

    checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true" "\"Gateway1OrgMSP\": true"
    checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true" "\"Gateway1OrgMSP\": true"
    checkCommitReadiness 5 "\"Org1MSP\": true" "\"Org2MSP\": true" "\"Gateway1OrgMSP\": true"

    commitChaincodeDefinition 1 2 5

elif [ "$CHANNEL_NAME" == "domain2channel" ]; then
    infoln "Installing chaincode on org3 peer..."
    installChaincode 3
    infoln "Install chaincode on org4 peer..."
    installChaincode 4
    infoln "Install chaincode on gateway peer..."
    installChaincode 6

    queryInstalled 3

    approveForMyOrg 3
    approveForMyOrg 4
    approveForMyOrg 6

    checkCommitReadiness 3 "\"Org3MSP\": true" "\"Org4MSP\": true" "\"Gateway2OrgMSP\": true"
    checkCommitReadiness 4 "\"Org3MSP\": true" "\"Org4MSP\": true" "\"Gateway2OrgMSP\": true"
    checkCommitReadiness 6 "\"Org3MSP\": true" "\"Org4MSP\": true" "\"Gateway2OrgMSP\": true"

    commitChaincodeDefinition 3 4 6
else
    errorln "Unknown channel name: ${CHANNEL_NAME}"
    exit 1
fi

## query whether the chaincode is installed
if [ "$CHANNEL_NAME" == "gatewaychannel" ]; then
    queryCommitted 5  # 使用 GatewayOrg 查询
elif [ "$CHANNEL_NAME" == "domain1channel" ]; then
    queryCommitted 1  # 使用 Org1 查询
elif [ "$CHANNEL_NAME" == "domain2channel" ]; then
    queryCommitted 3  # 使用 Org3 查询
else
    errorln "Unknown channel name: ${CHANNEL_NAME}"
    exit 1
fi

## Invoke the chaincode if required
if [ "$CC_INIT_FCN" = "NA" ]; then
  infoln "Chaincode initialization is not required"
else
  if [ "$CHANNEL_NAME" == "gatewaychannel" ]; then
    chaincodeInvokeInit 5 6 7 8 9 10 11 12
  elif [ "$CHANNEL_NAME" == "domain1channel" ]; then
    chaincodeInvokeInit 1 2 5
  elif [ "$CHANNEL_NAME" == "domain2channel" ]; then
    chaincodeInvokeInit 3 4 5
  fi
fi

exit 0