// cmd/initWallet/main.go
package main

import (
	"log"
	"os"
	"path/filepath"

	"github.com/hyperledger/fabric-sdk-go/pkg/gateway"
)

func main() {
    log.Println("============ 开始导入管理员证书 ============")

    // 获取当前工作目录
    currentDir, err := os.Getwd()
    if err != nil {
        log.Fatalf("获取工作目录失败: %v\n", err)
    }
    log.Printf("当前工作目录: %s", currentDir)

    // 确保钱包目录存在
    walletPath := filepath.Join(currentDir, "wallet")
    log.Printf("创建钱包目录: %s", walletPath)
    if err := os.MkdirAll(walletPath, 0755); err != nil {
        log.Fatalf("创建钱包目录失败: %v\n", err)
    }

    wallet, err := gateway.NewFileSystemWallet(walletPath)
    if err != nil {
        log.Fatalf("创建钱包失败: %v\n", err)
    }

    // 检查管理员身份是否已存在
    if wallet.Exists("admin") {
        log.Println("管理员身份已存在于钱包中")
        return
    }

    // 设置证书路径
    credPath := filepath.Join(
        "..",
        "organizations",
        "peerOrganizations",
        "org1.example.com",
        "users",
        "Admin@org1.example.com",
        "msp",
    )
    log.Printf("证书路径: %s", credPath)

    // 读取证书
    certPath := filepath.Join(credPath, "signcerts", "Admin@org1.example.com-cert.pem")
    log.Printf("正在读取证书: %s", certPath)
    cert, err := os.ReadFile(certPath)
    if err != nil {
        log.Fatalf("读取证书失败: %v\n", err)
    }

    // 读取私钥
    keyDir := filepath.Join(credPath, "keystore")
    files, err := os.ReadDir(keyDir)
    if err != nil {
        log.Fatalf("读取私钥目录失败: %v\n", err)
    }
    if len(files) < 1 {
        log.Fatalf("私钥文件不存在")
    }
    keyPath := filepath.Join(keyDir, files[0].Name())
    log.Printf("正在读取私钥: %s", keyPath)
    key, err := os.ReadFile(keyPath)
    if err != nil {
        log.Fatalf("读取私钥失败: %v\n", err)
    }

    // 创建身份
    identity := gateway.NewX509Identity("Org1MSP", string(cert), string(key))
    
    // 将身份导入钱包
    err = wallet.Put("admin", identity)
    if err != nil {
        log.Fatalf("导入身份失败: %v\n", err)
    }

    // 验证身份是否成功保存
    savedIdentity, err := wallet.Get("admin")
    if err != nil {
        log.Fatalf("验证身份失败: %v\n", err)
    }
    log.Printf("已保存的身份: %+v", savedIdentity)

    log.Println("管理员身份导入成功")
    log.Println("============ 导入管理员证书完成 ============")
}