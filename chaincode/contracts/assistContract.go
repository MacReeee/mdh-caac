package contracts

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

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



