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

# 节点1
ORG=1
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.yaml

# 节点2
ORG=2
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.yaml

# 节点3
ORG=3
P0PORT=11051
CAPORT=9054
PEERPEM=organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org3.example.com/connection-org3.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org3.example.com/connection-org3.yaml

# 节点4
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

# 网关6
ORG=10
P0PORT=7651
CAPORT=16054
PEERPEM=organizations/peerOrganizations/gateway6.example.com/tlsca/tlsca.gateway6.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway6.example.com/ca/ca.gateway6.example.com-cert.pem
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway6.example.com/connection-gateway6.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway6.example.com/connection-gateway6.yaml

# 网关7
ORG=11
P0PORT=7751
CAPORT=17054
PEERPEM=organizations/peerOrganizations/gateway7.example.com/tlsca/tlsca.gateway7.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway7.example.com/ca/ca.gateway7.example.com-cert.pem
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway7.example.com/connection-gateway7.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway7.example.com/connection-gateway7.yaml

# 网关8
ORG=12
P0PORT=7851
CAPORT=18054
PEERPEM=organizations/peerOrganizations/gateway8.example.com/tlsca/tlsca.gateway8.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway8.example.com/ca/ca.gateway8.example.com-cert.pem
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway8.example.com/connection-gateway8.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway8.example.com/connection-gateway8.yaml

# 网关9
ORG=13
P0PORT=7951
CAPORT=19054
PEERPEM=organizations/peerOrganizations/gateway9.example.com/tlsca/tlsca.gateway9.example.com-cert.pem
CAPEM=organizations/peerOrganizations/gateway9.example.com/ca/ca.gateway9.example.com-cert.pem
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway9.example.com/connection-gateway9.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway9.example.com/connection-gateway9.yaml

# # 网关10
# ORG=14
# P0PORT=8051
# CAPORT=20054
# PEERPEM=organizations/peerOrganizations/gateway10.example.com/tlsca/tlsca.gateway10.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway10.example.com/ca/ca.gateway10.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway10.example.com/connection-gateway10.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway10.example.com/connection-gateway10.yaml

# # 网关11
# ORG=15
# P0PORT=8151
# CAPORT=21054
# PEERPEM=organizations/peerOrganizations/gateway11.example.com/tlsca/tlsca.gateway11.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway11.example.com/ca/ca.gateway11.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway11.example.com/connection-gateway11.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway11.example.com/connection-gateway11.yaml

# # 网关12
# ORG=16
# P0PORT=8251
# CAPORT=22054
# PEERPEM=organizations/peerOrganizations/gateway12.example.com/tlsca/tlsca.gateway12.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway12.example.com/ca/ca.gateway12.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway12.example.com/connection-gateway12.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway12.example.com/connection-gateway12.yaml

# # 网关13
# ORG=17
# P0PORT=8351
# CAPORT=23054
# PEERPEM=organizations/peerOrganizations/gateway13.example.com/tlsca/tlsca.gateway13.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway13.example.com/ca/ca.gateway13.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway13.example.com/connection-gateway13.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway13.example.com/connection-gateway13.yaml

# # 网关14
# ORG=18
# P0PORT=8451
# CAPORT=24054
# PEERPEM=organizations/peerOrganizations/gateway14.example.com/tlsca/tlsca.gateway14.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway14.example.com/ca/ca.gateway14.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway14.example.com/connection-gateway14.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway14.example.com/connection-gateway14.yaml

# # 网关15
# ORG=19
# P0PORT=8551
# CAPORT=25054
# PEERPEM=organizations/peerOrganizations/gateway15.example.com/tlsca/tlsca.gateway15.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway15.example.com/ca/ca.gateway15.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway15.example.com/connection-gateway15.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway15.example.com/connection-gateway15.yaml

# # 网关16
# ORG=20
# P0PORT=8651
# CAPORT=26054
# PEERPEM=organizations/peerOrganizations/gateway16.example.com/tlsca/tlsca.gateway16.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway16.example.com/ca/ca.gateway16.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway16.example.com/connection-gateway16.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway16.example.com/connection-gateway16.yaml

# # 网关17
# ORG=21
# P0PORT=8751
# CAPORT=27054
# PEERPEM=organizations/peerOrganizations/gateway17.example.com/tlsca/tlsca.gateway17.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway17.example.com/ca/ca.gateway17.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway17.example.com/connection-gateway17.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway17.example.com/connection-gateway17.yaml

# # 网关18
# ORG=22
# P0PORT=8851
# CAPORT=28054
# PEERPEM=organizations/peerOrganizations/gateway18.example.com/tlsca/tlsca.gateway18.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/gateway18.example.com/ca/ca.gateway18.example.com-cert.pem
# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway18.example.com/connection-gateway18.json
# echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/gateway18.example.com/connection-gateway18.yaml