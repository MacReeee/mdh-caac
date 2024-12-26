package contracts

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// 用户身份结构
type Identity struct {
	Address string `json:"address"` // 用户地址
	MspID   string `json:"msp_id"`  // 组织 MSP ID
}

// 获取调用者身份函数
func (ac *AccessControlContract) getCallerIdentity(ctx contractapi.TransactionContextInterface) (Identity, error) {
	var identity Identity

	// 直接获取 Fabric ID 作为地址
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return identity, fmt.Errorf("failed to get identity: %v", err)
	}
	// ID 格式参考: x509::/C=US/ST=North Carolina/O=Hyperledger/OU=client/CN=user1::/C=US...
	identity.Address = id

	// 获取 MSP ID
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return identity, fmt.Errorf("failed to get MSP ID: %v", err)
	}
	identity.MspID = mspID

	return identity, nil
}

// 访问请求上下文
type RequestContext struct {
	Location LocationInfo `json:"location"`
	Time     int64        `json:"time"`
}

// 访问请求结构
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
	applicableRules, err := ac.getApplicableRules(ctx, request)
	if len(applicableRules) == 0 || err != nil {
		return false, fmt.Errorf("无可用规则")
	}

	// 遍历规则进行验证
	for _, rule := range applicableRules {
		// 验证主体约束
		if !ac.verifySubjectConstraints(ctx, rule.SubjectConstraints, request) {
			continue
		}

		// 验证资源约束
		if !ac.verifyResourceConstraints(rule.ResourceConstraints, request) {
			continue
		}

		// 验证上下文约束
		if !ac.verifyContextConstraints(rule.ContextConstraints, request) {
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
	Request   AccessRequest `json:"request"`   // 原始请求
	Allowed   bool          `json:"allowed"`   // 是否允许访问
	Timestamp int64         `json:"timestamp"` // 决策时间戳
	Reason    string        `json:"reason"`    // 决策原因
}

func generatePairKey(requester, owner Identity) string {
	return fmt.Sprintf("%s_%s", requester.Address, owner.Address)
}

// 添加新的访问记录
func (ac *AccessControlContract) recordAccessResult(ctx contractapi.TransactionContextInterface, result AccessResult) error {
	// 存储结果记录
	resultKey, err := ctx.GetStub().CreateCompositeKey("result", []string{result.Request.RequestID})
	if err != nil {
		return err
	}
	resultBytes, err := json.Marshal(result)
	if err != nil {
		return err
	}
	if err := ctx.GetStub().PutState(resultKey, resultBytes); err != nil {
		return err
	}

	// 存储按用户对的索引
	pairKey := generatePairKey(result.Request.Requester, result.Request.ResourceOwner)
	indexKey, err := ctx.GetStub().CreateCompositeKey("result_pair", []string{pairKey, result.Request.RequestID})
	if err != nil {
		return err
	}
	if err := ctx.GetStub().PutState(indexKey, []byte{0}); err != nil {
		return err
	}

	// 存储按资源的索引
	resourceKey, err := ctx.GetStub().CreateCompositeKey("result_resource",
		[]string{result.Request.ResourceID, result.Request.RequestID})
	if err != nil {
		return err
	}
	if ctx.GetStub().PutState(resourceKey, []byte{0}); err != nil {
		return err
	}

	if err := ac.updateDirectTrust(ctx, result); err != nil {
		return err
	}

	if err := ac.updateNodeContribution(ctx, result); err != nil {
		return err
	}

	if err := ac.updateDomainContribution(ctx, result); err != nil {
		return err
	}

	return nil
}

// 获取访问历史
func (ac *AccessControlContract) getAccessHistoryByIdentity(ctx contractapi.TransactionContextInterface,
	caller, resourceProvider Identity, startTime, endTime int64) ([]AccessResult, error) {

	results := []AccessResult{}
	pairKey := generatePairKey(caller, resourceProvider)

	// 获取该用户对的所有记录ID
	iterator, err := ctx.GetStub().GetStateByPartialCompositeKey("result_pair", []string{pairKey})
	if err != nil {
		return nil, err
	}
	defer iterator.Close()

	// 遍历获取每条记录
	for iterator.HasNext() {
		queryResponse, err := iterator.Next()
		if err != nil {
			return nil, err
		}

		// 从复合键中提取RequestID
		_, compositeKeyParts, err := ctx.GetStub().SplitCompositeKey(queryResponse.Key)
		if err != nil {
			return nil, err
		}
		requestID := compositeKeyParts[1]

		// 获取结果记录
		resultKey, err := ctx.GetStub().CreateCompositeKey("result", []string{requestID})
		if err != nil {
			return nil, err
		}
		resultBytes, err := ctx.GetStub().GetState(resultKey)
		if err != nil {
			return nil, err
		}

		var result AccessResult
		if err := json.Unmarshal(resultBytes, &result); err != nil {
			return nil, err
		}

		// 检查时间范围
		if result.Timestamp >= startTime && result.Timestamp <= endTime {
			results = append(results, result)
		}
	}

	return results, nil
}
