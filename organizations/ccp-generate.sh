#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=1
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.yaml

ORG=2
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.yaml

ORG=3
P0PORT=11051
CAPORT=9054
PEERPEM=organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org3.example.com/connection-org3.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org3.example.com/connection-org3.yaml

ORG=4
P0PORT=13051
CAPORT=10054
PEERPEM=organizations/peerOrganizations/org4.example.com/tlsca/tlsca.org4.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org4.example.com/ca/ca.org4.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org4.example.com/connection-org4.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org4.example.com/connection-org4.yaml

# 网关1
ORG=5 
P0PORT=7151
CAPORT=11054
PEERPEM=organizations/peerOrganizations/gateway1.example.com/tlsca/tlsca.gateway1.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway1.example.com/ca/ca.gateway1.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway1.example.com/connection-gateway1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway1.example.com/connection-gateway1.yaml

# 网关2
ORG=6
P0PORT=7251
CAPORT=12054
PEERPEM=organizations/peerOrganizations/gateway2.example.com/tlsca/tlsca.gateway2.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway2.example.com/ca/ca.gateway2.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway2.example.com/connection-gateway2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway2.example.com/connection-gateway2.yaml

# 网关3
ORG=7
P0PORT=7351
CAPORT=13054
PEERPEM=organizations/peerOrganizations/gateway3.example.com/tlsca/tlsca.gateway3.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway3.example.com/ca/ca.gateway3.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway3.example.com/connection-gateway3.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway3.example.com/connection-gateway3.yaml

# 网关4
ORG=8
P0PORT=7451
CAPORT=14054
PEERPEM=organizations/peerOrganizations/gateway4.example.com/tlsca/tlsca.gateway4.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway4.example.com/ca/ca.gateway4.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway4.example.com/connection-gateway4.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway4.example.com/connection-gateway4.yaml

# 网关5
ORG=9
P0PORT=7551
CAPORT=15054
PEERPEM=organizations/peerOrganizations/gateway5.example.com/tlsca/tlsca.gateway5.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway5.example.com/ca/ca.gateway5.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway5.example.com/connection-gateway5.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway5.example.com/connection-gateway5.yaml

# # 网关6
# ORG=10
# P0PORT=7651
# CAPORT=16054
# PEERPEM=organizations/peerOrganizations/gateway6.example.com/tlsca/tlsca.gateway6.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway6.example.com/ca/ca.gateway6.example.com-cert.pem

# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway6.example.com/connection-gateway6.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway6.example.com/connection-gateway6.yaml
