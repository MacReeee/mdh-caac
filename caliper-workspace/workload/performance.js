'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class PerformanceWorkload extends WorkloadModuleBase {
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
            console.log(`开始性能测试初始化 - Worker ${this.workerIndex}, Round ${roundIndex}`);
            if (!this.resourcesRegistered) {
                await this.registerResources();
                this.resourcesRegistered = true;
                console.log('性能测试资源注册完成');
            }
            
            if (!this.ruleDeployed) {
                await this.deployRule();
                this.ruleDeployed = true;
                console.log('性能测试规则部署完成');
            }
            
            await new Promise(resolve => setTimeout(resolve, 3000));
        } else {
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }

    async registerResources() {
        console.log('开始注册性能测试资源...');
        for (let i = 0; i < 5; i++) {
            const resource = {
                id: `perf_resource_${i}`,
                type: "document",
                description: `性能测试资源 ${i}`
            };

            const args = {
                contractId: 'mdh',
                contractFunction: 'RegisterResource',
                contractArguments: [JSON.stringify(resource), ""],
                readOnly: false
            };

            try {
                await this.sutAdapter.sendRequests(args);
                console.log(`性能测试资源 ${i} 注册成功`);
            } catch (error) {
                console.error(`性能测试资源 ${i} 注册失败:`, error);
                throw error;
            }
        }
    }

    async deployRule() {
        console.log('开始部署性能测试规则...');
        const rule = {
            rule_id: "perf_rule001",
            priority: 1,
            effect: "ALLOW",
            subject_constraints: {
                authorized_addresses: ["test_address"],
                required_roles: []
            },
            resource_constraints: {
                resource_ids: ["perf_resource_0", "perf_resource_1", "perf_resource_2", "perf_resource_3", "perf_resource_4"]
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
            console.log('性能测试规则部署成功');
        } catch (error) {
            console.error('性能测试规则部署失败:', error);
            throw error;
        }
    }

    async submitTransaction() {
        if (this.workerIndex === 0 && (!this.resourcesRegistered || !this.ruleDeployed)) {
            console.log('性能测试初始化未完成，跳过请求');
            return;
        }

        const resourceId = `perf_resource_${Math.floor(Math.random() * 5)}`;
        const request = {
            request_id: `perf_req_${Math.floor(Math.random() * 10000)}`,
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
                time: Math.floor(Date.now() / 1000)
            },
            timestamp: Math.floor(Date.now() / 1000)
        };

        const startTime = Date.now();
        const args = {
            contractId: 'mdh',
            contractFunction: 'RequestAccess',
            contractArguments: [JSON.stringify(request)],
            readOnly: false
        };

        try {
            await this.sutAdapter.sendRequests(args);
            const endTime = Date.now();
            const latency = endTime - startTime;
            
            console.log(`访问请求完成: ${request.request_id}, 延迟: ${latency}ms`);
        } catch (error) {
            console.error(`访问请求失败: ${request.request_id}`, error);
            throw error;
        }
    }
}

function createWorkloadModule() {
    return new PerformanceWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;