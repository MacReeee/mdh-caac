package contracts

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// 访问控制合约
type AccessControlContract struct {
	contractapi.Contract
}

// 初始化合约
func (ac *AccessControlContract) InitContract() error {
	return nil
}

// 部署新的访问规则
func (ac *AccessControlContract) DeployRule(ctx contractapi.TransactionContextInterface, ruleJSON string) error {
	// 获取调用者身份
	invoker, err := ac.getCallerIdentity(ctx)
	if err != nil {
		return fmt.Errorf("调用者身份验证失败: %v", err)
	}

	// 验证调用者权限
	if isAuth, err := ac.isAuthorizedDeployer(ctx, invoker); !isAuth {
		if err != nil {
			return fmt.Errorf("部署者验证失败: %v", err)
		}
		return fmt.Errorf("不是合法部署者: %s", invoker)
	}

	// 解析规则JSON
	var rule AccessRule
	err = json.Unmarshal([]byte(ruleJSON), &rule)
	if err != nil {
		return fmt.Errorf("JSON解析失败: %v", err)
	}

	// 验证规则格式
	if err := ac.validateRule(rule); err != nil {
		return fmt.Errorf("规则格式错误: %v", err)
	}

	// 检查规则冲突
	if err := ac.checkRuleConflicts(ctx, rule); err != nil {
		return fmt.Errorf("规则冲突: %v", err)
	}

	// 存储规则
	ruleKey, err := ctx.GetStub().CreateCompositeKey("rule", []string{rule.RuleID})
	if err != nil {
		return err
	}
	ruleBytes, err := json.Marshal(rule)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(ruleKey, ruleBytes)
}

// 访问请求
func (ac *AccessControlContract) RequestAccess(ctx contractapi.TransactionContextInterface, requestJSON string) (bool, error) {
	// 解析请求
	var request AccessRequest
	err := json.Unmarshal([]byte(requestJSON), &request)
	if err != nil {
		result := AccessResult{
			Request:   request,
			Allowed:   false,
			Timestamp: time.Now().Unix(),
			Reason:    "请求Json解析失败",
		}
		ac.recordAccessResult(ctx, result)
		return false, fmt.Errorf("failed to parse request JSON: %v", err)
	}

	// 执行访问控制判决
	allowed, err := ac.verifyAccessRequest(ctx, request)
	if err != nil {
		result := AccessResult{
			Request:   request,
			Allowed:   false,
			Timestamp: time.Now().Unix(),
			Reason:    err.Error(),
		}
		ac.recordAccessResult(ctx, result)
		return false, err
	}

	// 记录访问结果
	result := AccessResult{
		Request:   request,
		Allowed:   allowed,
		Timestamp: 0,
		Reason:    "基于规则判决",
	}
	ac.recordAccessResult(ctx, result)
	return allowed, nil
}

// 资源注册
func (ac *AccessControlContract) RegisterResource(ctx contractapi.TransactionContextInterface, resourceJSON string) error {
	// 获取并验证调用者身份
	owner, err := ac.getCallerIdentity(ctx)
	if err != nil {
		return fmt.Errorf("获取调用者身份失败: %v", err)
	}

	// 解析资源JSON
	var resource Resource
	if err := json.Unmarshal([]byte(resourceJSON), &resource); err != nil {
		return fmt.Errorf("解析资源JSON失败: %v", err)
	}

	// 验证资源ID不能为空
	if resource.ID == "" {
		return fmt.Errorf("资源ID不能为空")
	}

	// 检查资源是否已存在
	resourceKey, err := ctx.GetStub().CreateCompositeKey("resource", []string{resource.ID})
	if err != nil {
		return err
	}
	existing, err := ctx.GetStub().GetState(resourceKey)
	if err != nil {
		return err
	}
	if existing != nil {
		return fmt.Errorf("资源已存在: %s", resource.ID)
	}

	// 设置资源所有者和时间戳
	resource.Owner = owner
	resource.CreateTime = time.Now().Unix()
	resource.UpdateTime = resource.CreateTime

	// 存储资源
	resourceBytes, err := json.Marshal(resource)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(resourceKey, resourceBytes)
}

// 资源注销
func (ac *AccessControlContract) UnregisterResource(ctx contractapi.TransactionContextInterface, resourceID string) error {
	// 获取并验证调用者身份
	caller, err := ac.getCallerIdentity(ctx)
	if err != nil {
		return fmt.Errorf("获取调用者身份失败: %v", err)
	}

	// 获取资源信息
	resourceKey, err := ctx.GetStub().CreateCompositeKey("resource", []string{resourceID})
	if err != nil {
		return err
	}
	resourceBytes, err := ctx.GetStub().GetState(resourceKey)
	if err != nil {
		return err
	}
	if resourceBytes == nil {
		return fmt.Errorf("资源不存在: %s", resourceID)
	}

	var resource Resource
	if err := json.Unmarshal(resourceBytes, &resource); err != nil {
		return err
	}

	// 验证调用者是否为资源所有者
	if resource.Owner != caller {
		return fmt.Errorf("只有资源所有者可以注销资源")
	}

	// 删除资源
	return ctx.GetStub().DelState(resourceKey)
}

// 查询规则
// func (ac *AccessControlContract) GetRule(ctx contractapi.TransactionContextInterface, ruleID string) (string, error)

// 添加授权部署者
func (ac *AccessControlContract) AddAuthorizedDeployer(ctx contractapi.TransactionContextInterface, deployerJSON string) error {
	// 获取调用者身份
	invoker, err := ac.getCallerIdentity(ctx)
	if err != nil {
		return fmt.Errorf("调用者身份验证失败: %v", err)
	}

	// 验证调用者权限
	if isAuth, err := ac.isAuthorizedDeployer(ctx, invoker); !isAuth {
		if err != nil {
			return fmt.Errorf("部署者验证失败: %v", err)
		}
		return fmt.Errorf("不是合法部署者: %s", invoker)
	}

	// 解析部署者JSON
	var deployer Identity
	err = json.Unmarshal([]byte(deployerJSON), &deployer)
	if err != nil {
		return fmt.Errorf("JSON解析失败: %v", err)
	}

	// 存储部署者
	deployerKey, err := ctx.GetStub().CreateCompositeKey("deployer", []string{deployer.Address})
	if err != nil {
		return err
	}
	// 检查是否存在
	existing, err := ctx.GetStub().GetState(deployerKey)
	if err != nil {
		return err
	}
	if existing != nil {
		return fmt.Errorf("部署者已存在: %s", deployer.Address)
	}
	deployerBytes, err := json.Marshal(deployer)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(deployerKey, deployerBytes)
}

// 移除授权部署者
func (ac *AccessControlContract) RemoveAuthorizedDeployer(ctx contractapi.TransactionContextInterface, deployerID string) error {
	// 验证调用者身份和权限
	invoker, err := ac.getCallerIdentity(ctx)
	if err != nil {
		return fmt.Errorf("调用者身份验证失败: %v", err)
	}

	if isAuth, err := ac.isAuthorizedDeployer(ctx, invoker); !isAuth {
		if err != nil {
			return fmt.Errorf("部署者验证失败: %v", err)
		}
		return fmt.Errorf("不是合法部署者: %s", invoker)
	}

	// 检查要移除的部署者是否存在
	deployerKey, err := ctx.GetStub().CreateCompositeKey("deployer", []string{deployerID})
	if err != nil {
		return err
	}

	deployerBytes, err := ctx.GetStub().GetState(deployerKey)
	if err != nil {
		return err
	}
	if deployerBytes == nil {
		return fmt.Errorf("部署者不存在: %s", deployerID)
	}

	// 删除部署者
	return ctx.GetStub().DelState(deployerKey)
}
