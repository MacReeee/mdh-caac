package contracts

import (
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// 主体约束
type SubjectConstraints struct {
	AuthorizedAddresses []string `json:"authorized_addresses"`
	RequiredRoles       []string `json:"required_roles"`
}

func (ac *AccessControlContract) verifySubjectConstraints(ctx contractapi.TransactionContextInterface, constraints SubjectConstraints, request AccessRequest) bool {
	// 1. 验证地址是否在授权列表中
	for _, authorizedAddr := range constraints.AuthorizedAddresses {
		if authorizedAddr == request.Requester.Address {
			// 2. 如果地址匹配，继续验证角色
			if len(constraints.RequiredRoles) > 0 {
				// 获取用户的属性值（角色）
				for _, requiredRole := range constraints.RequiredRoles {
					val, ok, err := ctx.GetClientIdentity().GetAttributeValue(requiredRole)
					if err != nil || !ok || val != "true" {
						return false
					}
				}
			}
			return true
		}
	}

	return false
}

func (ac *AccessControlContract) verifySubjectConstraintsExtended(ctx contractapi.TransactionContextInterface, constraints SubjectConstraints, request AccessRequest) bool {
	// 1. 基础身份验证
	isAuthorized := false
	for _, authorizedAddr := range constraints.AuthorizedAddresses {
		if authorizedAddr == request.Requester.Address {
			isAuthorized = true
			break
		}
	}

	if !isAuthorized {
		return false
	}

	// 2. MSP组织验证
	requesterMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return false
	}

	// 如果请求者不是来自正确的组织，拒绝访问
	if requesterMSPID != request.Requester.MspID {
		return false
	}

	// 3. 角色验证
	if len(constraints.RequiredRoles) > 0 {
		clientID := ctx.GetClientIdentity()
		for _, role := range constraints.RequiredRoles {
			val, ok, err := clientID.GetAttributeValue(role)
			if err != nil || !ok || val != "true" {
				return false
			}
		}
	}

	// 4. 验证证书是否仍然有效
	cert, err := ctx.GetClientIdentity().GetX509Certificate()
	if err != nil {
		return false
	}

	now := time.Now()
	if now.Before(cert.NotBefore) || now.After(cert.NotAfter) {
		return false
	}

	return true
}
