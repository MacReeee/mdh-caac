#! /bin/bash

# 启动网络
./network.sh down
./network.sh up
./network.sh createChannel -c domain1channel
./network.sh deployCC -c domain1channel -ccn mdh -ccp ./chaincode -ccl go

# 配置环境变量
export PATH=$PATH:../bin
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# 注册资源
peer chaincode invoke -o localhost:7050 \
--ordererTLSHostnameOverride orderer.example.com \
--tls --cafile $ORDERER_CA \
-C domain1channel \
-n mdh \
-c '{"function":"RegisterResource","Args":["{\"id\":\"doc001\",\"type\":\"document\",\"description\":\"测试文档1号\"}", ""]}' \
--peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
--peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# 查询资源
peer chaincode invoke -o localhost:7050 \
--ordererTLSHostnameOverride orderer.example.com \
--tls --cafile $ORDERER_CA \
-C domain1channel \
-n mdh \
-c '{"function":"GetResource","Args":["doc001"]}' \
--peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
--peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# 查询身份
peer chaincode invoke -o localhost:7050 \
--ordererTLSHostnameOverride orderer.example.com \
--tls --cafile $ORDERER_CA \
-C domain1channel \
-n mdh \
-c '{"function":"GetCurrentIdentity","Args":[]}' \
--peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
--peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# 部署规则
peer chaincode invoke -o localhost:7050 \
--ordererTLSHostnameOverride orderer.example.com \
--tls --cafile $ORDERER_CA \
-C domain1channel \
-n mdh \
-c '{"function":"DeployRule","Args":["{\"rule_id\":\"rule001\",\"priority\":1,\"effect\":\"ALLOW\",\"subject_constraints\":{\"authorized_addresses\":[\"x509::CN=Admin@org1.example.com,OU=admin,L=San Francisco,ST=California,C=US::CN=ca.org1.example.com,O=org1.example.com,L=San Francisco,ST=California,C=US\"],\"required_roles\":[]},\"resource_constraints\":{\"resource_ids\":[\"doc001\"]},\"context_constraints\":{\"historic_constraints\":{\"required_trust_score\":0},\"time_constraints\":{\"start_time\":0,\"end_time\":1735660800},\"location_constraints\":{\"x_coordinate\":0,\"y_coordinate\":0,\"radius\":10000}},\"data_operations\":[0,1,2]}"]}' \
--peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
--peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# 成功访问
peer chaincode invoke -o localhost:7050 \
--ordererTLSHostnameOverride orderer.example.com \
--tls --cafile $ORDERER_CA \
-C domain1channel \
-n mdh \
-c '{"function":"RequestAccess","Args":["{\"request_id\":\"req001\",\"requester\":{\"address\":\"x509::CN=Admin@org1.example.com,OU=admin,L=San Francisco,ST=California,C=US::CN=ca.org1.example.com,O=org1.example.com,L=San Francisco,ST=California,C=US\",\"msp_id\":\"Org1MSP\"},\"resource_id\":\"doc001\",\"operation\":0,\"context\":{\"location\":{\"x_coordinate\":1,\"y_coordinate\":1},\"time\":1703653200},\"timestamp\":1703653200}"]}' \
--peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
--peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# 失败访问
peer chaincode invoke -o localhost:7050 \
--ordererTLSHostnameOverride orderer.example.com \
--tls --cafile $ORDERER_CA \
-C domain1channel \
-n mdh \
-c '{"function":"RequestAccess","Args":["{\"request_id\":\"req002\",\"requester\":{\"address\":\"x509::CN=Admin@org1.example.com,OU=admin,L=San Francisco,ST=California,C=US::CN=ca.org1.example.com,O=org1.example.com,L=San Francisco,ST=California,C=US\",\"msp_id\":\"Org1MSP\"},\"resource_id\":\"doc001\",\"operation\":0,\"context\":{\"location\":{\"x_coordinate\":20000,\"y_coordinate\":20000},\"time\":1703653200},\"timestamp\":1703653200}"]}' \
--peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
--peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt