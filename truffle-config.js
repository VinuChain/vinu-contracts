const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');
const privateKey = fs.readFileSync(".secret").toString().trim();

module.exports = {
    networks: {
        // Другие настройки сетей
        private: {
            provider: () => new HDWalletProvider(privateKey, `https://for-test.vinuchain-rpc.com`),
            network_id: 207207,
            // Другие параметры сети
        }
    },
    // Другие конфигурации
};