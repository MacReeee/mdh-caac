package contracts

type Resource struct {
	ID          string   `json:"id"`
	Owner       Identity `json:"owner"` // 资源所有者
	Type        string   `json:"type"`  // 资源类型
	Description string   `json:"description"`
	CreateTime  int64    `json:"create_time"`
	UpdateTime  int64    `json:"update_time"`
}
