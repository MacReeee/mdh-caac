package fabric

import (
    "encoding/json"
    "fmt"
)

type Resource struct {
    ID          string `json:"id"`
    Type        string `json:"type"`
    Description string `json:"description"`
}

func (setup *FabricSetup) RegisterResource(resource *Resource) error {
    if !setup.initialized {
        return fmt.Errorf("Fabric客户端未初始化")
    }

    resourceJSON, err := json.Marshal(resource)
    if err != nil {
        return fmt.Errorf("资源序列化失败: %v", err)
    }

    _, err = setup.Contract.SubmitTransaction("RegisterResource", string(resourceJSON), "")
    if err != nil {
        return fmt.Errorf("注册资源失败: %v", err)
    }

    return nil
}

func (setup *FabricSetup) QueryResource(resourceID string) (*Resource, error) {
    if !setup.initialized {
        return nil, fmt.Errorf("Fabric客户端未初始化")
    }

    result, err := setup.Contract.EvaluateTransaction("GetResource", resourceID)
    if err != nil {
        return nil, fmt.Errorf("查询资源失败: %v", err)
    }

    resource := &Resource{}
    err = json.Unmarshal(result, resource)
    if err != nil {
        return nil, fmt.Errorf("解析资源数据失败: %v", err)
    }

    return resource, nil
}
