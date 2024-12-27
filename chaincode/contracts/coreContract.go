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

// GetCurrentIdentity 返回当前调用者的身份信息
func (ac *AccessControlContract) GetCurrentIdentity(ctx contractapi.TransactionContextInterface) (*Identity, error) {
	identity, err := ac.getCallerIdentity(ctx)
	if err != nil {
		return nil, fmt.Errorf("获取身份失败: %v", err)
	}
	return &identity, nil
}

// 部署新的访问规则, 现阶段应该是谁都可以部署
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
		return fmt.Errorf("failed to create rule key: %v", err)
	}
	ruleBytes, err := json.Marshal(rule)
	if err != nil {
		return fmt.Errorf("failed to marshal rule: %v", err)
	}

	// 使用事务性写入 - 要么全部成功,要么全部失败
	for _, resourceID := range rule.ResourceConstraints.ResourceIDs {
		// 验证资源是否存在
		resourceKey, err := ctx.GetStub().CreateCompositeKey("resource", []string{resourceID})
		if err != nil {
			return fmt.Errorf("failed to create resource key: %v", err)
		}
		resource, err := ctx.GetStub().GetState(resourceKey)
		if err != nil {
			return fmt.Errorf("failed to get resource: %v", err)
		}
		if resource == nil {
			return fmt.Errorf("resource not found: %s", resourceID)
		}

		// 创建资源-规则映射
		resourceRuleKey, err := createResourceRuleKey(ctx, resourceID, rule.RuleID)
		if err != nil {
			return fmt.Errorf("failed to create resource-rule key: %v", err)
		}

		// 直接存储规则内容而不是规则键
		if err := ctx.GetStub().PutState(resourceRuleKey, ruleBytes); err != nil {
			return fmt.Errorf("failed to store resource-rule mapping: %v", err)
		}
	}

	// 最后存储规则本身
	if err := ctx.GetStub().PutState(ruleKey, ruleBytes); err != nil {
		return fmt.Errorf("failed to store rule: %v", err)
	}

	return nil
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
func (ac *AccessControlContract) RegisterResource(ctx contractapi.TransactionContextInterface, resourceJSON, ruleID string) error {
	// 获取并验证调用者身份
	owner, err := ac.getCallerIdentity(ctx)
	if err != nil {
		fmt.Printf("获取调用者身份失败: %v\n", err)
		return fmt.Errorf("获取调用者身份失败: %v", err)
	}
	fmt.Printf("Resource registration initiated by: %v\n", owner)

	// 解析资源JSON
	var resource Resource
	if err := json.Unmarshal([]byte(resourceJSON), &resource); err != nil {
		fmt.Printf("解析资源JSON失败: %v\n", err)
		return fmt.Errorf("解析资源JSON失败: %v", err)
	}
	fmt.Printf("Resource parsed: %+v\n", resource)

	// 验证资源ID不能为空
	if resource.ID == "" {
		return fmt.Errorf("资源ID不能为空")
	}

	// 创建资源键
	resourceKey, err := ctx.GetStub().CreateCompositeKey("resource", []string{resource.ID})
	if err != nil {
		fmt.Printf("创建资源键失败: %v\n", err)
		return err
	}
	fmt.Printf("Resource key created: %s\n", resourceKey)

	// 检查资源是否已存在
	existing, err := ctx.GetStub().GetState(resourceKey)
	if err != nil {
		fmt.Printf("检查资源存在性失败: %v\n", err)
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
		fmt.Printf("序列化资源失败: %v\n", err)
		return err
	}
	if err := ctx.GetStub().PutState(resourceKey, resourceBytes); err != nil {
		fmt.Printf("存储资源失败: %v\n", err)
		return err
	}
	fmt.Printf("Resource successfully registered: %s\n", resource.ID)

	return nil
}
