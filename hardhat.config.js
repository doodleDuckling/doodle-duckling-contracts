// hardhat.config.js
const {projectId, mnemonic} = require('./secrets.json');

require("@nomiclabs/hardhat-ethers");
require('@openzeppelin/hardhat-upgrades');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity:
        {
            compilers:
                [
                    {
                        version: '0.8.11',
                        settings: {
                            optimizer: {enabled: true, runs: 200},
                            // evmVersion: 'istanbul',
                        },
                    },
                ],
        },
    networks: {
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${projectId}`,
            accounts: {mnemonic: mnemonic}
        },
        ganache: {
            url: 'http://127.0.0.1:7545',
            accounts: {mnemonic: mnemonic}
        },
        // bsc: {
        //     url: `https://bsc-dataseed1.ninicoin.io/`,
        //     accounts: ['0x']
        // }
    }
};
