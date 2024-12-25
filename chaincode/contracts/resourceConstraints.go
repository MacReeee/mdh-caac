package contracts

// 资源约束
type ResourceConstraints struct {
	ResourceIDs []string `json:"resource_ids"`
}

func (ac *AccessControlContract) verifyResourceConstraints(constraints ResourceConstraints, request AccessRequest) bool {
	// 验证资源ID是否在允许列表中
	for _, rid := range constraints.ResourceIDs {
		if rid == request.ResourceID {
			return true
		}
	}
	return false
}
