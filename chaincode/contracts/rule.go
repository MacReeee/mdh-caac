package contracts

import (
	"fmt"
	"sort"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

const (
	debug = true
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
	RuleID             string              `json:"rule_id"`
	Priority           int                 `json:"priority"`
	Effect             Effect              `json:"effect"`              // allow/deny
	SubjectAttributes  SubjectConstraints  `json:"subject_attributes"`  // 主体约束
	ResourceAttributes ResourceConstraints `json:"resource_attributes"` // 资源约束
	ContextInformation ContextConstraints  `json:"context_information"` // 上下文约束
	DataOperations     []operation         `json:"data_operations"`     // 允许的操作
}

// 验证规则部署交易发起者是否合法
func (ac *AccessControlContract) isAuthorizedDeployer(ctx contractapi.TransactionContextInterface, identity Identity) bool {
	// 测试目的，只要是通道成员就直接返回true
	if debug {
		// 1. 验证MSP ID是否有效
		if identity.MspID == "" {
			return false
		}

		// 2. 验证证书是否有效
		cert, err := ctx.GetClientIdentity().GetX509Certificate()
		if err != nil {
			return false
		}

		// 检查证书是否在有效期内
		now := time.Now()
		if now.Before(cert.NotBefore) || now.After(cert.NotAfter) {
			return false
		}

		// 3. 在测试环境中，只要上述验证通过就允许部署
		return true
	}

	// 遍历已授权的部署者
	for _, authorized := range ac.AuthorizedDeployers {
		if authorized.Address == identity.Address &&
			authorized.MspID == identity.MspID {
			return true
		}
	}
	return false
}

// 验证规则格式是否合法
func (ac *AccessControlContract) validateRule(rule AccessRule) error {
	if rule.RuleID == "" {
		return fmt.Errorf("rule ID is empty")
	}
	if rule.Effect != EffectAllow && rule.Effect != EffectDeny {
		return fmt.Errorf("invalid effect value")
	}
	return nil
}

// 检查规则冲突
func (ac *AccessControlContract) checkRuleConflicts(newRule AccessRule) error {
	for _, existingRule := range ac.Rules {
		// 检查规则ID冲突
		if existingRule.RuleID == newRule.RuleID {
			return fmt.Errorf("rule ID already exists")
		}
	}
	return nil
}

// 获取适用的规则
func (ac *AccessControlContract) getApplicableRules(request AccessRequest) []AccessRule {
	var applicable []AccessRule
	for _, rule := range ac.Rules {
		// 检查资源ID是否匹配
		for _, rid := range rule.ResourceAttributes.ResourceIDs {
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
	return applicable
}
