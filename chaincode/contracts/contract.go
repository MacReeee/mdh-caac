package contracts

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// 访问控制合约
type AccessControlContract struct {
	contractapi.Contract

	// 已部署的规则映射
	Rules map[string]AccessRule

	// 授权部署规则的用户列表
	AuthorizedDeployers []Identity

	// 访问历史记录
	AccessHistory AccessHistory
}

// 初始化合约
func (ac *AccessControlContract) InitContract() error {
	ac.Rules = make(map[string]AccessRule)
	ac.AccessHistory = AccessHistory{
		Results:    make([]AccessResult, 0),
		ByPair:     make(map[string][]int),
		ByResource: make(map[string][]int),
	}
	return nil
}

// 部署新的访问规则
func (ac *AccessControlContract) DeployRule(ctx contractapi.TransactionContextInterface, ruleJSON string) error {
	// 获取调用者身份
	invoker, err := ac.getCallerIdentity(ctx)
	if err != nil {
		return fmt.Errorf("failed to get invoker identity: %v", err)
	}

	// 验证调用者权限
	if !ac.isAuthorizedDeployer(ctx, invoker) {
		return fmt.Errorf("unauthorized deployer: %s", invoker)
	}

	// 解析规则JSON
	var rule AccessRule
	err = json.Unmarshal([]byte(ruleJSON), &rule)
	if err != nil {
		return fmt.Errorf("failed to parse rule JSON: %v", err)
	}

	// 验证规则格式
	if err := ac.validateRule(rule); err != nil {
		return fmt.Errorf("invalid rule: %v", err)
	}

	// 检查规则冲突
	if err := ac.checkRuleConflicts(rule); err != nil {
		return fmt.Errorf("rule conflicts detected: %v", err)
	}

	// 存储规则
	ruleKey := fmt.Sprintf("rule_%s", rule.RuleID)
	ruleBytes, err := json.Marshal(rule)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(ruleKey, ruleBytes)
}

// 访问请求
func (ac *AccessControlContract) RequestAccess(ctx contractapi.TransactionContextInterface, requestJSON string) (bool, error)

// 撤销规则
func (ac *AccessControlContract) RevokeRule(ctx contractapi.TransactionContextInterface, ruleID string) error

// 更新规则
func (ac *AccessControlContract) UpdateRule(ctx contractapi.TransactionContextInterface, ruleJSON string) error

// 资源注册
func (ac *AccessControlContract) RegisterResource(ctx contractapi.TransactionContextInterface, resourceJSON string) error

// 资源注销
func (ac *AccessControlContract) UnregisterResource(ctx contractapi.TransactionContextInterface, resourceID string) error

// 查询规则
func (ac *AccessControlContract) GetRule(ctx contractapi.TransactionContextInterface, ruleID string) (string, error)

// 查询资源访问记录
func (ac *AccessControlContract) GetAccessHistory(ctx contractapi.TransactionContextInterface, requesterID string, resourceID string) (string, error)

// 添加授权部署者
func (ac *AccessControlContract) AddAuthorizedDeployer(ctx contractapi.TransactionContextInterface, deployerJSON string) error

// 移除授权部署者
func (ac *AccessControlContract) RemoveAuthorizedDeployer(ctx contractapi.TransactionContextInterface, deployerID string) error
