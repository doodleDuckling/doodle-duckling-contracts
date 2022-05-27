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
            accounts: ['0xe4d049df90ef78f45079810dcec2f039e300f987631f043a2797a864b00d59da']
        },
        bsc: {
            url: `https://bsc-dataseed1.ninicoin.io/`,
            accounts: {mnemonic: mnemonic}
        },
        bsctest: {
            url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
            accounts: {mnemonic: mnemonic}
        }
    }
};
