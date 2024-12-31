'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class AccessWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.resourcesRegistered = false;
        this.ruleDeployed = false;
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutContext, sutAdapter) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutContext, sutAdapter);
        this.workerIndex = workerIndex;
        
        // 只让 worker 0 进行初始化工作
        if (this.workerIndex === 0) {
            console.log('Worker 0 开始初始化...');
            if (!this.resourcesRegistered) {
                await this.registerResources();
                this.resourcesRegistered = true;
                console.log('资源注册完成');
            }
            
            if (!this.ruleDeployed) {
                await this.deployRule();
                this.ruleDeployed = true;
                console.log('规则部署完成');
            }
            
            // 等待初始化操作生效
            console.log('等待初始化操作生效...');
            await new Promise(resolve => setTimeout(resolve, 3000));
        } else {
            // 其他 worker 等待初始化完成
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }

    async registerResources() {
        console.log('开始注册测试资源...');
        for (let i = 0; i < 5; i++) {
            const resource = {
                id: `resource_${i}`,
                type: "document",
                description: `测试资源 ${i}`
            };

            const args = {
                contractId: 'mdh',
                contractFunction: 'RegisterResource',
                contractArguments: [JSON.stringify(resource), ""],
                readOnly: false
            };

            try {
                await this.sutAdapter.sendRequests(args);
                console.log(`资源 ${i} 注册成功`);
            } catch (error) {
                console.error(`资源 ${i} 注册失败:`, error);
                throw error;
            }
        }
    }

    async deployRule() {
        console.log('开始部署访问规则...');
        const rule = {
            rule_id: "rule001",
            priority: 1,
            effect: "ALLOW",
            subject_constraints: {
                authorized_addresses: ["test_address"],
                required_roles: []
            },
            resource_constraints: {
                resource_ids: ["resource_0", "resource_1", "resource_2", "resource_3", "resource_4"]
            },
            context_constraints: {
                historic_constraints: {
                    required_trust_score: 0
                },
                time_constraints: {
                    start_time: 0,
                    end_time: 1735660800
                },
                location_constraints: {
                    x_coordinate: 0,
                    y_coordinate: 0,
                    radius: 10000
                }
            },
            data_operations: [0, 1, 2]
        };

        const args = {
            contractId: 'mdh',
            contractFunction: 'DeployRule',
            contractArguments: [JSON.stringify(rule)],
            readOnly: false
        };

        try {
            await this.sutAdapter.sendRequests(args);
            console.log('规则部署成功');
        } catch (error) {
            console.error('规则部署失败:', error);
            throw error;
        }
    }

    async submitTransaction() {
        if (this.workerIndex === 0 && (!this.resourcesRegistered || !this.ruleDeployed)) {
            console.log('初始化未完成，跳过访问请求');
            return;
        }

        const resourceId = `resource_${Math.floor(Math.random() * 5)}`; // 0-4
        const request = {
            request_id: `req_${Math.floor(Math.random() * 10000)}`,
            requester: {
                address: "test_address",
                msp_id: "Org1MSP"
            },
            resource_id: resourceId,
            operation: 0,
            context: {
                location: {
                    x_coordinate: Math.random() * 100,
                    y_coordinate: Math.random() * 100
                },
                time: Math.floor(Date.now() / 1000) // 转换为秒
            },
            timestamp: Math.floor(Date.now() / 1000)
        };

        // console.log(`发送访问请求: ${request.request_id}, 资源: ${request.resource_id}`);

        const args = {
            contractId: 'mdh',
            contractFunction: 'RequestAccess',
            contractArguments: [JSON.stringify(request)],
            readOnly: false
        };

        await this.sutAdapter.sendRequests(args);
    }
}

function createWorkloadModule() {
    return new AccessWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;