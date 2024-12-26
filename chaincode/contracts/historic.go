package contracts

import (
	"encoding/json"
	"fmt"
	"math"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// 域内访问计数器
type DomainAccessCounter struct {
	Domain        string           `json:"domain"`         // 域标识
	TotalAccesses int64            `json:"total_accesses"` // 域内总访问次数
	NodeAccesses  map[string]int64 `json:"node_accesses"`  // 各节点访问次数
	LastUpdated   int64            `json:"last_updated"`   // 最后更新时间
}

// 全局访问计数器
type GlobalAccessCounter struct {
	TotalAccesses  int64            `json:"total_accesses"`  // 总访问次数
	DomainAccesses map[string]int64 `json:"domain_accesses"` // 各域访问次数
	LastUpdated    int64            `json:"last_updated"`    // 最后更新时间
}

// 创建计数器的复合键
func createDomainCounterKey(ctx contractapi.TransactionContextInterface, domain string) (string, error) {
	return ctx.GetStub().CreateCompositeKey("DomainCounter", []string{domain})
}

const GlobalCounterKey = "GlobalCounter"

// 状态数据库复合键前缀
const (
	DirectTrustObjectType        = "directTrust"
	NodeContributionObjectType   = "nodeContribution"
	DomainContributionObjectType = "domainContribution"
)

// 直接信任值结构
type DirectTrust struct {
	FromNode    Identity `json:"from_node"`    // 信任值评估方
	ToNode      Identity `json:"to_node"`      // 被评估方
	TrustValue  float64  `json:"trust_value"`  // 信任值
	LastUpdated int64    `json:"last_updated"` // 最后更新时间
}

// 创建复合键
func createDirectTrustKey(ctx contractapi.TransactionContextInterface, from, to Identity) (string, error) {
	return ctx.GetStub().CreateCompositeKey(DirectTrustObjectType, []string{from.Address, to.Address})
}

func (ac *AccessControlContract) updateDirectTrust(ctx contractapi.TransactionContextInterface, result AccessResult) error {
	// 计算参数
	const (
		alpha = 0.1 // 时间衰减因子
		W     = 10  // 时间窗口
		v1    = 1.0 // 成功访问效用值
		v0    = 0.0 // 失败访问效用值
	)

	// 获取当前状态的信任值
	trustKey, err := createDirectTrustKey(ctx, result.Request.Requester, result.Request.ResourceOwner)
	if err != nil {
		return fmt.Errorf("failed to create trust key: %v", err)
	}
	trustBytes, err := ctx.GetStub().GetState(trustKey)

	var currentTrust DirectTrust
	if err != nil || trustBytes == nil {
		// 如果不存在，创建新的信任值记录
		currentTrust = DirectTrust{
			FromNode:    result.Request.Requester,
			ToNode:      result.Request.ResourceOwner,
			TrustValue:  0.0,
			LastUpdated: result.Timestamp,
		}
	} else {
		if err := json.Unmarshal(trustBytes, &currentTrust); err != nil {
			return err
		}
	}

	// 获取历史访问记录
	history, err := ac.getAccessHistoryByIdentity(ctx,
		result.Request.Requester,
		result.Request.ResourceOwner,
		result.Timestamp-W,
		result.Timestamp)
	if err != nil {
		return err
	}

	// 计算新的信任值
	numerator := 0.0
	denominator := 1.0
	currentTime := result.Timestamp

	for _, record := range history {
		h := v0
		if record.Allowed {
			h = v1
		}
		timeDiff := float64(currentTime - record.Timestamp)
		decay := math.Exp(-alpha * timeDiff)

		numerator += h * decay
		denominator += v1 * decay
	}

	// 更新信任值
	currentTrust.TrustValue = numerator / denominator
	currentTrust.LastUpdated = currentTime

	// 存储更新后的信任值
	trustBytes, err = json.Marshal(currentTrust)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(trustKey, trustBytes)
}

// 节点贡献度结构
type NodeContribution struct {
	Domain      string   `json:"domain"`       // 所属域
	Node        Identity `json:"node"`         // 节点身份
	Value       float64  `json:"value"`        // 贡献度值
	LastUpdated int64    `json:"last_updated"` // 最后更新时间
}

func createNodeContributionKey(ctx contractapi.TransactionContextInterface, domain string, node Identity) (string, error) {
	return ctx.GetStub().CreateCompositeKey(NodeContributionObjectType, []string{domain, node.Address})
}

// 更新节点贡献度
func (ac *AccessControlContract) updateNodeContribution(ctx contractapi.TransactionContextInterface, result AccessResult) error {
	// 获取域计数器
	domain := result.Request.ResourceOwner.MspID
	counterKey, err := createDomainCounterKey(ctx, domain)
	if err != nil {
		return fmt.Errorf("failed to create counter key: %v", err)
	}

	counterBytes, err := ctx.GetStub().GetState(counterKey)
	var counter DomainAccessCounter
	if err != nil || counterBytes == nil {
		counter = DomainAccessCounter{
			Domain:        domain,
			TotalAccesses: 0,
			NodeAccesses:  make(map[string]int64),
			LastUpdated:   result.Timestamp,
		}
	} else {
		if err := json.Unmarshal(counterBytes, &counter); err != nil {
			return fmt.Errorf("failed to unmarshal counter: %v", err)
		}
	}

	// 更新计数
	counter.TotalAccesses++
	if _, exists := counter.NodeAccesses[result.Request.ResourceOwner.Address]; !exists {
		counter.NodeAccesses[result.Request.ResourceOwner.Address] = 0
	}
	counter.NodeAccesses[result.Request.ResourceOwner.Address]++
	counter.LastUpdated = result.Timestamp

	// 计算并更新节点贡献度
	nodeContribKey, err := createNodeContributionKey(ctx, domain, result.Request.ResourceOwner)
	if err != nil {
		return fmt.Errorf("failed to create node contribution key: %v", err)
	}

	contribution := NodeContribution{
		Domain:      domain,
		Node:        result.Request.ResourceOwner,
		Value:       float64(counter.NodeAccesses[result.Request.ResourceOwner.Address]) / float64(counter.TotalAccesses),
		LastUpdated: result.Timestamp,
	}

	// 保存更新后的计数器和贡献度
	counterBytes, err = json.Marshal(counter)
	if err != nil {
		return fmt.Errorf("failed to marshal counter: %v", err)
	}
	if err := ctx.GetStub().PutState(counterKey, counterBytes); err != nil {
		return fmt.Errorf("failed to save counter: %v", err)
	}

	contribBytes, err := json.Marshal(contribution)
	if err != nil {
		return fmt.Errorf("failed to marshal contribution: %v", err)
	}
	if err := ctx.GetStub().PutState(nodeContribKey, contribBytes); err != nil {
		return fmt.Errorf("failed to save node contribution: %v", err)
	}

	return nil
}

// 域贡献度结构
type DomainContribution struct {
	Domain      string  `json:"domain"`       // 域标识
	Value       float64 `json:"value"`        // 贡献度值
	LastUpdated int64   `json:"last_updated"` // 最后更新时间
}

func createDomainContributionKey(ctx contractapi.TransactionContextInterface, domain string) (string, error) {
	return ctx.GetStub().CreateCompositeKey(DomainContributionObjectType, []string{domain})
}

// 更新域贡献度
func (ac *AccessControlContract) updateDomainContribution(ctx contractapi.TransactionContextInterface, result AccessResult) error {
	// 获取全局计数器
	counterBytes, err := ctx.GetStub().GetState(GlobalCounterKey)
	var counter GlobalAccessCounter
	if err != nil || counterBytes == nil {
		counter = GlobalAccessCounter{
			TotalAccesses:  0,
			DomainAccesses: make(map[string]int64),
			LastUpdated:    result.Timestamp,
		}
	} else {
		if err := json.Unmarshal(counterBytes, &counter); err != nil {
			return fmt.Errorf("failed to unmarshal counter: %v", err)
		}
	}

	// 更新计数
	domain := result.Request.ResourceOwner.MspID
	counter.TotalAccesses++
	if _, exists := counter.DomainAccesses[domain]; !exists {
		counter.DomainAccesses[domain] = 0
	}
	counter.DomainAccesses[domain]++
	counter.LastUpdated = result.Timestamp

	// 计算并更新域贡献度
	domainContribKey, err := createDomainContributionKey(ctx, domain)
	if err != nil {
		return fmt.Errorf("failed to create domain contribution key: %v", err)
	}

	contribution := DomainContribution{
		Domain:      domain,
		Value:       float64(counter.DomainAccesses[domain]) / float64(counter.TotalAccesses),
		LastUpdated: result.Timestamp,
	}

	// 保存更新后的计数器和贡献度
	counterBytes, err = json.Marshal(counter)
	if err != nil {
		return fmt.Errorf("failed to marshal counter: %v", err)
	}
	if err := ctx.GetStub().PutState(GlobalCounterKey, counterBytes); err != nil {
		return fmt.Errorf("failed to save counter: %v", err)
	}

	contribBytes, err := json.Marshal(contribution)
	if err != nil {
		return fmt.Errorf("failed to marshal contribution: %v", err)
	}
	if err := ctx.GetStub().PutState(domainContribKey, contribBytes); err != nil {
		return fmt.Errorf("failed to save domain contribution: %v", err)
	}

	return nil
}
