package main

type Identity struct {
    Address string `json:"address"`
    MspID   string `json:"msp_id"`
}

type LocationInfo struct {
    XCoordinate float64 `json:"x_coordinate"`
    YCoordinate float64 `json:"y_coordinate"`
}

type TimeConstraints struct {
    StartTime int64 `json:"start_time"`
    EndTime   int64 `json:"end_time"`
}

type LocationConstraints struct {
    XCoordinate float64 `json:"x_coordinate"`
    YCoordinate float64 `json:"y_coordinate"`
    Radius      float64 `json:"radius"`
}

type HistoricConstraints struct {
    RequiredTrustScore float64 `json:"required_trust_score"`
}

type ContextConstraints struct {
    HistoricConstraints HistoricConstraints `json:"historic_constraints"`
    TimeConstraints     TimeConstraints     `json:"time_constraints"`
    LocationConstraints LocationConstraints `json:"location_constraints"`
}

type SubjectConstraints struct {
    AuthorizedAddresses []string `json:"authorized_addresses"`
    RequiredRoles       []string `json:"required_roles"`
}

type ResourceConstraints struct {
    ResourceIDs []string `json:"resource_ids"`
}

type AccessRule struct {
    RuleID              string              `json:"rule_id"`
    Priority            int                 `json:"priority"`
    Effect              string              `json:"effect"`
    SubjectConstraints  SubjectConstraints  `json:"subject_constraints"`
    ResourceConstraints ResourceConstraints `json:"resource_constraints"`
    ContextConstraints  ContextConstraints  `json:"context_constraints"`
    DataOperations      []int               `json:"data_operations"`
}

type RequestContext struct {
    Location LocationInfo `json:"location"`
    Time     int64       `json:"time"`
}

type AccessRequest struct {
    RequestID     string         `json:"request_id"`
    Requester     Identity       `json:"requester"`
    ResourceID    string         `json:"resource_id"`
    ResourceOwner Identity       `json:"resource_owner"`
    Operation     int            `json:"operation"`
    Context       RequestContext `json:"context"`
    Timestamp     int64          `json:"timestamp"`
}