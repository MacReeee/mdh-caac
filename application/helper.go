package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/hyperledger/fabric-sdk-go/pkg/gateway"
)

// Helper 函数
func populateWallet(wallet *gateway.Wallet) error {
	// 读取证书文件
	credPath := "../organizations/peerOrganizations/org1.example.com"
	certPath := credPath + "/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem"
	cert, err := os.ReadFile(filepath.Clean(certPath))
	if err != nil {
		return fmt.Errorf("读取证书文件失败: %v", err)
	}

	// 读取私钥文件
	keyDir := credPath + "/users/Admin@org1.example.com/msp/keystore"
	files, err := os.ReadDir(keyDir)
	if err != nil {
		return fmt.Errorf("读取密钥目录失败: %v", err)
	}
	if len(files) < 1 {
		return fmt.Errorf("在%s目录中未找到密钥文件", keyDir)
	}
	key, err := os.ReadFile(filepath.Join(keyDir, files[0].Name()))
	if err != nil {
		return fmt.Errorf("读取密钥文件失败: %v", err)
	}

	identity := gateway.NewX509Identity("Org1MSP", string(cert), string(key))

	err = wallet.Put("admin", identity)
	if err != nil {
		return fmt.Errorf("将管理员身份放入钱包失败: %v", err)
	}

	return nil
}

// 获取当前身份信息
func (app *TestApp) getCurrentIdentityInfo() (*Identity, error) {
	result, err := app.contract.EvaluateTransaction("GetCurrentIdentity")
	if err != nil {
		return nil, fmt.Errorf("获取身份信息失败: %v", err)
	}

	var identity Identity
	if err := json.Unmarshal(result, &identity); err != nil {
		return nil, fmt.Errorf("解析身份信息失败: %v", err)
	}

	return &identity, nil
}
