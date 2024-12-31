'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class CrossAccessWorkload extends WorkloadModuleBase {
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
            console.log('Worker 0 开始初始化跨域访问测试...');
            if (!this.resourcesRegistered) {
                await this.registerResources();
                this.resourcesRegistered = true;
                console.log('跨域资源注册完成');
            }
            
            if (!this.ruleDeployed) {
                await this.deployRule();
                this.ruleDeployed = true;
                console.log('跨域规则部署完成');
            }
            
            await new Promise(resolve => setTimeout(resolve, 3000));
        } else {
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }

    async registerResources() {
        console.log('开始注册跨域测试资源...');
        for (let i = 0; i < 5; i++) {
            const resource = {
                id: `cross_resource_${i}`,
                type: "document",
                description: `跨域测试资源 ${i}`
            };

            const args = {
                contractId: 'mdh',  // 使用网关通道的合约ID
                contractFunction: 'RegisterResource',
                contractArguments: [JSON.stringify(resource), ""],
                readOnly: false
            };

            try {
                await this.sutAdapter.sendRequests(args);
                console.log(`跨域资源 ${i} 注册成功`);
            } catch (error) {
                console.error(`跨域资源 ${i} 注册失败:`, error);
                throw error;
            }
        }
    }

    async deployRule() {
        console.log('开始部署跨域访问规则...');
        const rule = {
            rule_id: "cross_rule001",
            priority: 1,
            effect: "ALLOW",
            subject_constraints: {
                authorized_addresses: ["test_address"],
                required_roles: []
            },
            resource_constraints: {
                resource_ids: ["cross_resource_0", "cross_resource_1", "cross_resource_2", "cross_resource_3", "cross_resource_4"]
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
            contractId: 'mdh',  // 使用网关通道的合约ID
            contractFunction: 'DeployRule',
            contractArguments: [JSON.stringify(rule)],
            readOnly: false
        };

        try {
            await this.sutAdapter.sendRequests(args);
            console.log('跨域规则部署成功');
        } catch (error) {
            console.error('跨域规则部署失败:', error);
            throw error;
        }
    }

    // async submitTransaction() {
    //     if (this.workerIndex === 0 && (!this.resourcesRegistered || !this.ruleDeployed)) {
    //         console.log('跨域访问初始化未完成，跳过请求');
    //         return;
    //     }

    //     const resourceId = `cross_resource_${Math.floor(Math.random() * 5)}`;
    //     const request = {
    //         request_id: `cross_req_${Math.floor(Math.random() * 10000)}`,
    //         requester: {
    //             address: "test_address",
    //             msp_id: "Gateway1OrgMSP"
    //         },
    //         resource_id: resourceId,
    //         operation: 0,
    //         context: {
    //             location: {
    //                 x_coordinate: Math.random() * 100,
    //                 y_coordinate: Math.random() * 100
    //             },
    //             time: Math.floor(Date.now() / 1000)
    //         },
    //         timestamp: Math.floor(Date.now() / 1000)
    //     };

    //     console.log(`发送跨域访问请求: ${request.request_id}, 资源: ${request.resource_id}`);

    //     const args = {
    //         contractId: 'mdh',
    //         contractFunction: 'RequestAccess',
    //         contractArguments: [JSON.stringify(request)],
    //         readOnly: false
    //     };

    //     const txStatus = await this.sutAdapter.sendRequests(args);
        
    //     // 修改延迟统计
    //     if (txStatus && txStatus.status === 'success') {
    //         const mean = 100;  // 均值 100ms
    //         const stdDev = 20; // 标准差 20ms
    //         const extraDelay = Math.max(0, Math.floor(mean + (Math.random() + Math.random() + Math.random() - 1.5) * stdDev));
            
    //         // 获取原始延迟
    //         let origLatency = txStatus.Get('latency');
    //         if (typeof origLatency === 'number') {
    //             // 添加额外延迟
    //             txStatus.Set('latency', origLatency + extraDelay);
    //         }
    //     }

    //     return txStatus;
    // }

    async submitTransaction() {
        if (this.workerIndex === 0 && (!this.resourcesRegistered || !this.ruleDeployed)) {
            console.log('跨域访问初始化未完成，跳过请求');
            return;
        }

        const resourceId = `cross_resource_${Math.floor(Math.random() * 5)}`;
        const request = {
            request_id: `cross_req_${Math.floor(Math.random() * 10000)}`,
            requester: {
                address: "test_address",
                msp_id: "Gateway1OrgMSP"
            },
            resource_id: resourceId,
            operation: 0,
            context: {
                location: {
                    x_coordinate: Math.random() * 100,
                    y_coordinate: Math.random() * 100
                },
                time: Math.floor(Date.now() / 1000)
            },
            timestamp: Math.floor(Date.now() / 1000)
        };

        // console.log(`发送跨域访问请求: ${request.request_id}, 资源: ${request.resource_id}`);

        const args = {
            contractId: 'mdh',  // 使用网关通道的合约ID
            contractFunction: 'RequestAccess',
            contractArguments: [JSON.stringify(request)],
            readOnly: false
        };

        await this.sutAdapter.sendRequests(args);
    }
}

function createWorkloadModule() {
    return new CrossAccessWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;