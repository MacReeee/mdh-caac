package contracts

import (
	"encoding/json"
	"fmt"
	"sort"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

const (
	test = true
)

// 满足条件时允许还是拒绝
type Effect string

const (
	EffectDeny  Effect = "DENY"
	EffectAllow Effect = "ALLOW"
)

func (e Effect) IsValid() bool {
	return e == EffectDeny || e == EffectAllow
}

// 数据操作类型
type operation int

const (
	Read  operation = 0
	Write operation = 1
	Excu  operation = 2
)

// 访问规则结构
type AccessRule struct {
	RuleID              string              `json:"rule_id"`
	Priority            int                 `json:"priority"`
	Effect              Effect              `json:"effect"`              // allow/deny
	SubjectConstraints  SubjectConstraints  `json:"subject_constraints"`  // 主体约束
	ResourceConstraints ResourceConstraints `json:"resource_constraints"` // 资源约束
	ContextConstraints  ContextConstraints  `json:"context_constraints"` // 上下文约束
	DataOperations      []operation         `json:"data_operations"`     // 允许的操作
}

// 验证规则部署交易发起者是否合法
func (ac *AccessControlContract) isAuthorizedDeployer(ctx contractapi.TransactionContextInterface, identity Identity) (bool, error) {
	isMemberFunc := func() (bool, error) {
		// 1. 验证MSP ID是否有效
		if identity.MspID == "" {
			return false, fmt.Errorf("MSP ID为空")
		}

		// 2. 验证证书是否有效
		cert, err := ctx.GetClientIdentity().GetX509Certificate()
		if err != nil {
			return false, fmt.Errorf("获取X509证书失败: %v", err)
		}

		// 3. 检查证书是否在有效期内
		now := time.Now()
		if now.Before(cert.NotBefore) || now.After(cert.NotAfter) {
			return false, fmt.Errorf("证书已过期")
		}

		// 4. 在测试环境中，只要上述验证通过就允许部署
		return true, nil
	}

	isAuthurizedFunc := func() (bool, error) {
		// 遍历已授权的部署者
		authDeploys, err := ctx.GetStub().GetStateByPartialCompositeKey("authorizedDeployer", []string{})
		if err != nil {
			return false, err
		}
		for authDeploys.HasNext() {
			queryRespinse, err := authDeploys.Next()
			if err != nil {
				return false, err
			}

			var authorizedDeployer Identity
			if err := json.Unmarshal(queryRespinse.Value, &authorizedDeployer); err != nil {
				return false, err
			}

			if authorizedDeployer == identity {
				return true, nil
			}
		}

		return false, nil
	}

	if test { // 测试目的，只要是通道成员就直接返回true
		return isMemberFunc()
	}
	return isAuthurizedFunc()
}

// 验证规则格式是否合法
func (ac *AccessControlContract) validateRule(rule AccessRule) error {
	if rule.RuleID == "" {
		return fmt.Errorf("规则ID为空")
	}
	if rule.Effect != EffectAllow && rule.Effect != EffectDeny {
		return fmt.Errorf("规则效果无效")
	}
	return nil
}

// 检查规则冲突
func (ac *AccessControlContract) checkRuleConflicts(ctx contractapi.TransactionContextInterface, newRule AccessRule) error {
	iterator, err := ctx.GetStub().GetStateByPartialCompositeKey("rule", []string{})
	if err != nil {
		return err
	}
	defer iterator.Close()

	for iterator.HasNext() {
		queryResponse, err := iterator.Next()
		if err != nil {
			return err
		}

		var existingRule AccessRule
		if err := json.Unmarshal(queryResponse.Value, &existingRule); err != nil {
			return err
		}

		if existingRule.RuleID == newRule.RuleID {
			return fmt.Errorf("规则ID已存在")
		}
	}
	return nil
}

// 获取适用的规则
func (ac *AccessControlContract) getApplicableRules(ctx contractapi.TransactionContextInterface, request AccessRequest) ([]AccessRule, error) {
	var applicable []AccessRule

	iterator, err := ctx.GetStub().GetStateByPartialCompositeKey("rule", []string{})
	if err != nil {
		return nil, err
	}
	defer iterator.Close()

	for iterator.HasNext() {
		queryResponse, err := iterator.Next()
		if err != nil {
			return nil, err
		}

		var rule AccessRule
		if err := json.Unmarshal(queryResponse.Value, &rule); err != nil {
			return nil, err
		}

		// 检查资源ID是否匹配
		for _, rid := range rule.ResourceConstraints.ResourceIDs {
			if rid == request.ResourceID {
				applicable = append(applicable, rule)
				break
			}
		}
	}

	// 规则按优先级排序
	sort.Slice(applicable, func(i, j int) bool {
		return applicable[i].Priority > applicable[j].Priority
	})

	return applicable, nil
}
