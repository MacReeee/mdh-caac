export PATH=$PATH:../bin
export FABRIC_CFG_PATH=../config

# 1. 查看 Org1 的 peer0
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

echo "===== peer0.org1 的channel列表 ====="
peer channel list

# 2. 查看 Org2 的 peer0
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

echo "===== peer0.org2 的channel列表 ====="
peer channel list

# 3. 查看 Org3 的 peer0
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:11051

echo "===== peer0.org3 的channel列表 ====="
peer channel list

# 4. 查看 Org4 的 peer0
export CORE_PEER_LOCALMSPID="Org4MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
export CORE_PEER_ADDRESS=localhost:13051

echo "===== peer0.org4 的channel列表 ====="
peer channel list

# 5. 查看 Gateway1Org 的 peer0
export CORE_PEER_LOCALMSPID="Gateway1OrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/gateway1.example.com/peers/peer0.gateway1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway1.example.com/users/Admin@gateway1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7151

echo "===== peer0.gateway1 的channel列表 ====="
peer channel list

# 6. 查看 Gateway2Org 的 peer0
export CORE_PEER_LOCALMSPID="Gateway2OrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/gateway2.example.com/peers/peer0.gateway2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway2.example.com/users/Admin@gateway2.example.com/msp
export CORE_PEER_ADDRESS=localhost:7251

echo "===== peer0.gateway2 的channel列表 ====="
peer channel list

# 7. 查看 Gateway3Org 的 peer0
export CORE_PEER_LOCALMSPID="Gateway3OrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/gateway3.example.com/peers/peer0.gateway3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway3.example.com/users/Admin@gateway3.example.com/msp
export CORE_PEER_ADDRESS=localhost:7351

echo "===== peer0.gateway3 的channel列表 ====="
peer channel list

# 8. 查看 Gateway4Org 的 peer0
export CORE_PEER_LOCALMSPID="Gateway4OrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/gateway4.example.com/peers/peer0.gateway4.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway4.example.com/users/Admin@gateway4.example.com/msp
export CORE_PEER_ADDRESS=localhost:7451

echo "===== peer0.gateway4 的channel列表 ====="
peer channel list

# 9. 查看 Gateway5Org 的 peer0
export CORE_PEER_LOCALMSPID="Gateway5OrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/gateway5.example.com/peers/peer0.gateway5.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway5.example.com/users/Admin@gateway5.example.com/msp
export CORE_PEER_ADDRESS=localhost:7551

echo "===== peer0.gateway5 的channel列表 ====="
peer channel list

# 10. 查看 Gateway6Org 的 peer0
export CORE_PEER_LOCALMSPID="Gateway6OrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/gateway6.example.com/peers/peer0.gateway6.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/gateway6.example.com/users/Admin@gateway6.example.com/msp

echo "===== peer0.gateway6 的channel列表 ====="
peer channel list