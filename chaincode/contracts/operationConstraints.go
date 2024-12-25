package contracts

// 验证数据操作
func (ac *AccessControlContract) verifyOperationConstraints(allowedOps []operation, request AccessRequest) bool {
	for _, op := range allowedOps {
		if op == request.Operation {
			return true
		}
	}
	return false
}
