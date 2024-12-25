package main

import (
	"log"
	"mdhcaac/contracts"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {
	AccessControlContract, err := contractapi.NewChaincode(&contracts.AccessControlContract{})
	if err != nil {
		log.Println("访问控制合约初始化失败: ", err)
	}

	if err := AccessControlContract.Start(); err != nil {
		log.Println("访问控制合约启动失败: ", err)
	}
}
