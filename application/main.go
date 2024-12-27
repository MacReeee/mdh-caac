package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
	"github.com/hyperledger/fabric-sdk-go/pkg/gateway"
)

// 定义应用程序结构
type TestApp struct {
	gateway  *gateway.Gateway
	network  *gateway.Network
	contract *gateway.Contract
}

// 初始化TestApp实例
func NewTestApp() (*TestApp, error) {
	// 初始化wallet并添加身份信息
	wallet := gateway.NewInMemoryWallet()
	err := populateWallet(wallet) // 需要实现此helper函数
	if err != nil {
		return nil, fmt.Errorf("初始化钱包失败: %v", err)
	}

	// 连接到gateway
	gw, err := gateway.Connect(
		gateway.WithConfig(config.FromFile("connection.yaml")),
		gateway.WithIdentity(wallet, "admin"),
	)
	if err != nil {
		return nil, fmt.Errorf("连接到网关失败: %v", err)
	}

	// 获取网络和合约
	network, err := gw.GetNetwork("domain1channel")
	if err != nil {
		return nil, fmt.Errorf("获取网络失败: %v", err)
	}

	contract := network.GetContract("mdh")

	return &TestApp{
		gateway:  gw,
		network:  network,
		contract: contract,
	}, nil
}

// 注册资源
func (app *TestApp) RegisterResource() error {
	resource := map[string]interface{}{
		"id":          "doc001",
		"type":        "document",
		"description": "测试文档1号",
	}

	resourceJSON, err := json.Marshal(resource)
	if err != nil {
		return fmt.Errorf("资源序列化失败: %v", err)
	}

	result, err := app.contract.SubmitTransaction("RegisterResource", string(resourceJSON), "")
	if err != nil {
		return fmt.Errorf("注册资源失败: %v", err)
	}

	fmt.Printf("资源注册成功: %s\n", result)
	return nil
}

// 查询资源
func (app *TestApp) GetResource(resourceID string) error {
	result, err := app.contract.EvaluateTransaction("GetResource", resourceID)
	if err != nil {
		return fmt.Errorf("查询资源失败: %v", err)
	}

	fmt.Printf("资源详情: %s\n", result)
	return nil
}

// 查询当前身份
func (app *TestApp) GetCurrentIdentity() error {
	result, err := app.contract.EvaluateTransaction("GetCurrentIdentity")
	if err != nil {
		return fmt.Errorf("查询当前身份失败: %v", err)
	}

	fmt.Printf("当前身份: %s\n", result)
	return nil
}

// 部署访问规则
func (app *TestApp) DeployRule(identity *Identity) error {
	rule := AccessRule{
		RuleID:   "rule001",
		Priority: 1,
		Effect:   "ALLOW",
		SubjectConstraints: SubjectConstraints{
			AuthorizedAddresses: []string{identity.Address},
			RequiredRoles:       []string{},
		},
		ResourceConstraints: ResourceConstraints{
			ResourceIDs: []string{"doc001"},
		},
		ContextConstraints: ContextConstraints{
			HistoricConstraints: HistoricConstraints{
				RequiredTrustScore: 0,
			},
			TimeConstraints: TimeConstraints{
				StartTime: 0,
				EndTime:   1735660800,
			},
			LocationConstraints: LocationConstraints{
				XCoordinate: 0,
				YCoordinate: 0,
				Radius:      10000,
			},
		},
		DataOperations: []int{0, 1, 2},
	}

	ruleJSON, err := json.Marshal(rule)
	if err != nil {
		return fmt.Errorf("规则序列化失败: %v", err)
	}

	result, err := app.contract.SubmitTransaction("DeployRule", string(ruleJSON))
	if err != nil {
		return fmt.Errorf("部署规则失败: %v", err)
	}

	fmt.Printf("规则部署成功: %s\n", result)
	return nil
}

// 发起访问请求
func (app *TestApp) RequestAccess(isSuccess bool) error {
	// 获取当前身份信息
	identity, err := app.getCurrentIdentityInfo()
	if err != nil {
		return fmt.Errorf("获取当前身份信息失败: %v", err)
	}

	// 构建位置信息
	xCoord := 1.0
	yCoord := 1.0
	if !isSuccess {
		xCoord = 20000.0
		yCoord = 20000.0
	}

	request := AccessRequest{
		RequestID:  fmt.Sprintf("req_%d", time.Now().Unix()),
		Requester:  *identity,
		ResourceID: "doc001",
		Operation:  0,
		Context: RequestContext{
			Location: LocationInfo{
				XCoordinate: xCoord,
				YCoordinate: yCoord,
			},
			Time: time.Now().Unix(),
		},
		Timestamp: time.Now().Unix(),
	}

	requestJSON, err := json.Marshal(request)
	if err != nil {
		return fmt.Errorf("请求序列化失败: %v", err)
	}

	result, err := app.contract.SubmitTransaction("RequestAccess", string(requestJSON))
	if err != nil {
		return fmt.Errorf("提交访问请求失败: %v", err)
	}

	fmt.Printf("访问请求结果: %s\n", result)
	return nil
}

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	app, err := NewTestApp()
	if err != nil {
		log.Fatalf("创建应用程序失败: %v", err)
	}

	// 获取身份
	identity, err := app.getCurrentIdentityInfo()
	if err != nil {
		log.Fatalf("获取当前身份失败: %v", err)
	}
	// 执行测试
	fmt.Println("1. 测试注册资源")
	if err := app.RegisterResource(); err != nil {
		log.Printf("注册资源失败: %v", err)
	}

	fmt.Println("\n2. 测试查询资源")
	if err := app.GetResource("doc001"); err != nil {
		log.Printf("查询资源失败: %v", err)
	}

	fmt.Println("\n3. 测试查询当前身份")
	if err := app.GetCurrentIdentity(); err != nil {
		log.Printf("查询当前身份失败: %v", err)
	}

	fmt.Println("\n4. 测试部署规则")
	if err := app.DeployRule(identity); err != nil {
		log.Printf("部署规则失败: %v", err)
	}

	fmt.Println("\n5. 测试访问请求（成功场景）")
	if err := app.RequestAccess(true); err != nil {
		log.Printf("访问请求（成功）失败: %v", err)
	}

	fmt.Println("\n6. 测试访问请求（失败场景）")
	if err := app.RequestAccess(false); err != nil {
		log.Printf("访问请求（失败）失败: %v", err)
	}
}
