package contracts

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// 用户身份结构
type Identity struct {
	Address    string `json:"address"`     // 用户地址
	MspID      string `json:"msp_id"`      // 组织 MSP ID
	CommonName string `json:"common_name"` // 用户通用名称
}

// 获取调用者身份的辅助函数
func (ac *AccessControlContract) getCallerIdentity(ctx contractapi.TransactionContextInterface) (Identity, error) {
	var identity Identity

	// 直接获取 Fabric ID 作为地址
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return identity, fmt.Errorf("failed to get identity: %v", err)
	}
	// ID 格式类似: x509::/C=US/ST=North Carolina/O=Hyperledger/OU=client/CN=user1::/C=US...
	identity.Address = id

	// 获取 MSP ID
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return identity, fmt.Errorf("failed to get MSP ID: %v", err)
	}
	identity.MspID = mspID

	// 获取证书中的通用名称
	cert, err := ctx.GetClientIdentity().GetX509Certificate()
	if err != nil {
		return identity, fmt.Errorf("failed to get X509 certificate: %v", err)
	}
	identity.CommonName = cert.Subject.CommonName

	return identity, nil
}

// 访问请求结构
type RequestContext struct {
	Location LocationInfo `json:"location"`
	Time     string       `json:"time"`
}

type AccessRequest struct {
	RequestID     string         `json:"request_id"`
	Requester     Identity       `json:"requester"`
	ResourceID    string         `json:"resource_id"`
	ResourceOwner Identity       `json:"resource_owner"`
	Operation     operation      `json:"operation"`
	Context       RequestContext `json:"context"`
	Timestamp     int64          `json:"timestamp"`
}

// 验证访问请求
func (ac *AccessControlContract) verifyAccessRequest(ctx contractapi.TransactionContextInterface, request AccessRequest) (bool, error) {
	// 获取适用的规则
	applicableRules := ac.getApplicableRules(request)
	if len(applicableRules) == 0 {
		return false, fmt.Errorf("no applicable rules found")
	}

	// 遍历规则进行验证
	for _, rule := range applicableRules {
		// 验证主体约束
		if !ac.verifySubjectConstraints(ctx, rule.SubjectAttributes, request) {
			continue
		}

		// 验证资源约束
		if !ac.verifyResourceConstraints(rule.ResourceAttributes, request) {
			continue
		}

		// 验证上下文约束
		if !ac.verifyContextConstraints(rule.ContextInformation, request) {
			continue
		}

		// 验证操作约束
		if !ac.verifyOperationConstraints(rule.DataOperations, request) {
			continue
		}

		// 所有约束都验证通过，返回规则效果
		return rule.Effect == EffectAllow, nil
	}

	// 如果没有匹配的规则，默认拒绝访问
	return false, nil
}

// 访问结果
type AccessResult struct {
	Request     AccessRequest `json:"request"`      // 原始请求
	Allowed     bool          `json:"allowed"`      // 是否允许访问
	AppliedRule string        `json:"applied_rule"` // 应用的规则ID
	Timestamp   int64         `json:"timestamp"`    // 决策时间戳
	Reason      string        `json:"reason"`       // 决策原因
}

// 访问历史记录
type AccessHistory struct {
	Results    []AccessResult   `json:"results"`     // 所有访问结果
	ByPair     map[string][]int `json:"by_pair"`     // "requester_owner" -> Result indices
	ByResource map[string][]int `json:"by_resource"` // ResourceID -> Result indices
}

func generatePairKey(requester, owner Identity) string {
	return fmt.Sprintf("%s_%s", requester.Address, owner.Address)
}

// write: 添加新的访问记录
func (ac *AccessControlContract) recordAccessResult(result AccessResult) {
	// 获取新记录将被插入的索引位置
	newIndex := len(ac.AccessHistory.Results)

	// 添加结果到Results数组
	ac.AccessHistory.Results = append(ac.AccessHistory.Results, result)

	// 添加索引到ByPair映射
	pairKey := generatePairKey(result.Request.Requester, result.Request.ResourceOwner)
	if _, exists := ac.AccessHistory.ByPair[pairKey]; !exists {
		ac.AccessHistory.ByPair[pairKey] = make([]int, 0)
	}
	ac.AccessHistory.ByPair[pairKey] = append(ac.AccessHistory.ByPair[pairKey], newIndex)

	// 添加索引到ByResource映射
	if _, exists := ac.AccessHistory.ByResource[result.Request.ResourceID]; !exists {
		ac.AccessHistory.ByResource[result.Request.ResourceID] = make([]int, 0)
	}
	ac.AccessHistory.ByPair[pairKey] = append(ac.AccessHistory.ByPair[pairKey], newIndex)
}

// read: 获取指定身份、指定时间范围的访问历史
func (ac *AccessControlContract) getAccessHistoryByIdentity(caller, resourceProvider Identity, startTime, endTime int64) ([]AccessResult, error) {
	result := make([]AccessResult, 0)
	pairKey := generatePairKey(caller, resourceProvider)
	indices, exists := ac.AccessHistory.ByPair[pairKey]
	if !exists {
		return result, nil
	}
	for _, idx := range indices {
		if ac.AccessHistory.Results[idx].Timestamp >= startTime && ac.AccessHistory.Results[idx].Timestamp <= endTime {
			result = append(result, ac.AccessHistory.Results[idx])
		}
	}
	return result, nil
}
