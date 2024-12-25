package contracts

// 上下文约束
type ContextConstraints struct {
	HistoricConstraints HistoricConstraints `json:"historic_constraints"`
	TimeConstraints     TimeConstraints     `json:"time_constraints"`
	LocationConstraints LocationConstraints `json:"location_constraints"`
}

type HistoricConstraints struct {
	RequiredTrustScore float64 `json:"required_trust_score"`
}

func (ac *AccessControlContract) verifyHistoricConstraints(constraints HistoricConstraints, param any) bool {
	// TODO: implement
	return true
}

type TimeConstraints struct {
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
}

func (ac *AccessControlContract) verifyTimeConstraints(constraints TimeConstraints, time string) bool {
	// TODO: implement
	return true
}

type LocationConstraints struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Radius    float64 `json:"radius"` // 米为单位
}

func (ac *AccessControlContract) verifyLocationConstraints(constraints LocationConstraints, location LocationInfo) bool {
	// TODO: implement
	return true
}

type LocationInfo struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

func (ac *AccessControlContract) verifyContextConstraints(constraints ContextConstraints, request AccessRequest) bool {
	// 验证时间约束
	if !ac.verifyTimeConstraints(constraints.TimeConstraints, request.Context.Time) {
		return false
	}

	// 验证位置约束
	if !ac.verifyLocationConstraints(constraints.LocationConstraints, request.Context.Location) {
		return false
	}

	// 验证历史约束
	if !ac.verifyHistoricConstraints(constraints.HistoricConstraints, request.Requester) {
		return false
	}

	return true
}
