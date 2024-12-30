// cmd/main.go
package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"mdhapp/pkg/fabric"
)

func main() {
	fmt.Println(os.Getwd())
	// 初始化Fabric设置
	fabricSetup := &fabric.FabricSetup{
		ConfigFile:  filepath.Join("config", "config.yaml"),
		ChannelID:   "domain1channel",
		ChainCodeID: "mdh",
	}

	// 初始化Fabric客户端
	if err := fabricSetup.Initialize(); err != nil {
		log.Fatalf("初始化Fabric失败: %v", err)
	}
	defer fabricSetup.CleanUp()

	// 注册资源示例
	resource := &fabric.Resource{
		ID:          "doc001",
		Type:        "document",
		Description: "测试文档",
	}

	if err := fabricSetup.RegisterResource(resource); err != nil {
		log.Fatalf("注册资源失败: %v", err)
	}
	log.Printf("资源 %s 注册成功\n", resource.ID)

	// 查询资源示例
	queriedResource, err := fabricSetup.QueryResource(resource.ID)
	if err != nil {
		log.Fatalf("查询资源失败: %v", err)
	}
	log.Printf("查询到的资源: %+v\n", queriedResource)
}
