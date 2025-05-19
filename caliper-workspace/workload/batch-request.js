'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class ConcurrentRequestWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.resourcesRegistered = false;
        this.ruleDeployed = false;
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutContext, sutAdapter) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutContext, sutAdapter);
        
        this.workerIndex = workerIndex;
        this.concurrentLevel = roundArguments.concurrentLevel;
        
        if (this.workerIndex === 0) {
            if (!this.resourcesRegistered) {
                await this.registerResources();
                this.resourcesRegistered = true;
            }
            
            if (!this.ruleDeployed) {
                await this.deployRule();
                this.ruleDeployed = true;
            }
            
            await new Promise(resolve => setTimeout(resolve, 3000));
        } else {
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }

    async registerResources() {
        for (let i = 0; i < 10; i++) {
            const resource = {
                id: `concurrent_resource_${i}`,
                type: "document",
                description: `并发测试资源 ${i}`
            };

            const args = {
                contractId: 'mdh',
                contractFunction: 'RegisterResource',
                contractArguments: [JSON.stringify(resource), ""],
                readOnly: false
            };

            await this.sutAdapter.sendRequests(args);
        }
    }

    async deployRule() {
        const rule = {
            rule_id: "concurrent_rule001",
            priority: 1,
            effect: "ALLOW",
            subject_constraints: {
                authorized_addresses: ["test_address"],
                required_roles: []
            },
            resource_constraints: {
                resource_ids: Array.from({length: 10}, (_, i) => `concurrent_resource_${i}`)
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

        await this.sutAdapter.sendRequests(args);
    }

    async submitTransaction() {
        if (this.workerIndex === 0 && (!this.resourcesRegistered || !this.ruleDeployed)) {
            return;
        }

        const resourceId = `concurrent_resource_${Math.floor(Math.random() * 10)}`;
        const request = {
            request_id: `concurrent_req_${Math.floor(Math.random() * 10000)}`,
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

        const args = {
            contractId: 'mdh',
            contractFunction: 'RequestAccess',
            contractArguments: [JSON.stringify(request)],
            readOnly: false
        };

        // 在提交请求后添加适当延迟
        await this.sutAdapter.sendRequests(args);
        await new Promise(resolve => setTimeout(resolve, 100)); // 100ms延迟
    }
}

function createWorkloadModule() {
    return new ConcurrentRequestWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
