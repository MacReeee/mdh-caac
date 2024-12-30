'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class RegisterWorkload extends WorkloadModuleBase {
    constructor() {
        super();
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutContext, sutAdapter) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutContext, sutAdapter);
    }

    async submitTransaction() {
        const resourceId = `resource_${Math.floor(Math.random() * 10000)}`;
        const resource = {
            id: resourceId,
            type: "document",
            description: `Test resource ${resourceId}`
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

function createWorkloadModule() {
    return new RegisterWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;