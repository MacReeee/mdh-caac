package contracts

import "math"

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
	StartTime int64 `json:"start_time"`
	EndTime   int64 `json:"end_time"`
}

func (ac *AccessControlContract) verifyTimeConstraints(constraints TimeConstraints, time int64) bool {
	if time < constraints.StartTime || time > constraints.EndTime {
		return false
	}
	return true
}

type LocationConstraints struct {
	XCoordinate float64 `json:"x_coordinate"`
	YCoordinate float64 `json:"y_coordinate"`
	Radius      float64 `json:"radius"` // 米为单位
}

func (ac *AccessControlContract) verifyLocationConstraints(constraints LocationConstraints, location LocationInfo) bool {
	distance := math.Sqrt(math.Pow(location.XCoordinate-constraints.XCoordinate, 2) + math.Pow(location.YCoordinate-constraints.YCoordinate, 2))
	return distance <= constraints.Radius
}

type LocationInfo struct {
	XCoordinate float64 `json:"x_coordinate"`
	YCoordinate float64 `json:"y_coordinate"`
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
