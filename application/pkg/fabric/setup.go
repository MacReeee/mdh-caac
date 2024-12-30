// pkg/fabric/setup.go
package fabric

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
	"github.com/hyperledger/fabric-sdk-go/pkg/gateway"
)

type FabricSetup struct {
	ConfigFile  string
	ChannelID   string
	ChainCodeID string
	Gateway     *gateway.Gateway
	Network     *gateway.Network
	Contract    *gateway.Contract
	initialized bool
}

func (setup *FabricSetup) Initialize() error {
    log.Printf("开始初始化 Fabric SDK...")
    
    // 获取当前工作目录
    currentDir, err := os.Getwd()
    if err != nil {
        return fmt.Errorf("获取工作目录失败: %v", err)
    }
    log.Printf("当前工作目录: %s", currentDir)

    // 获取配置文件的绝对路径
    configPath, err := filepath.Abs(setup.ConfigFile)
    if err != nil {
        return fmt.Errorf("获取配置文件路径失败: %v", err)
    }
    log.Printf("配置文件路径: %s", configPath)

    // 创建钱包
    walletPath := filepath.Join(currentDir, "wallet")
    log.Printf("钱包路径: %s", walletPath)
    wallet, err := gateway.NewFileSystemWallet(walletPath)
    if err != nil {
        return fmt.Errorf("创建钱包失败: %v", err)
    }

    // 检查身份
    adminIdentity, err := wallet.Get("admin")
    if err != nil {
        return fmt.Errorf("获取admin身份失败: %v", err)
    }
    log.Printf("成功获取admin身份：%+v", adminIdentity)

    // 使用debug级别的配置
    gw, err := gateway.Connect(
        gateway.WithConfig(config.FromFile(setup.ConfigFile)),
        gateway.WithIdentity(wallet, "admin"),
    )
    if err != nil {
        return fmt.Errorf("创建Gateway失败: %v", err)
    }
    setup.Gateway = gw

    log.Printf("正在获取通道网络: %s", setup.ChannelID)
    network, err := setup.Gateway.GetNetwork(setup.ChannelID)
    if err != nil {
        log.Printf("获取通道网络失败详情：%+v", err)
        return fmt.Errorf("获取通道网络失败: %v", err)
    }

    setup.Network = network
    setup.Contract = network.GetContract(setup.ChainCodeID)
    setup.initialized = true

    return nil
}

func (setup *FabricSetup) CleanUp() {
	if setup.Gateway != nil {
		setup.Gateway.Close()
	}
}
