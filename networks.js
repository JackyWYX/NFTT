const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');
const PRIKEY = fs.existsSync(".secret") && fs.readFileSync(".secret").toString().trim();
module.exports = {
    heco_test: {
        provider: () => new HDWalletProvider(PRIKEY, "https://http-testnet.hecochain.com"),
        network_id: 256,
        skipDryRun: true
    },
    heco_main: {
        provider: () => new HDWalletProvider(PRIKEY, "https://http-mainnet-node.huobichain.com"),
        network_id: 128,
        skipDryRun: true,
    },
    bsc_test: {
        provider: () => new HDWalletProvider(PRIKEY, "https://data-seed-prebsc-1-s3.binance.org:8545/"),
        network_id: 97,
        skipDryRun: true
    },
    bsc_main: {
        provider: () => new HDWalletProvider(PRIKEY, "https://bsc-dataseed.binance.org"),
        network_id: 56,
        skipDryRun: true,
    },
    ok_test: {
        provider: () => new HDWalletProvider(PRIKEY, `https://exchaintestrpc.okex.org`),
        network_id: "65",       // Ropsten's id
        confirmations: 1,    // # of confs to wait between deployments. (default: 0)
        timeoutBlocks: 10,  // # of blocks before a deployment times out  (minimum/default: 50)
        skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    ok_main: {
        provider: () => new HDWalletProvider(PRIKEY, `https://exchainrpc.okex.org`),
        network_id: "66",       // Ropsten's id
        confirmations: 1,    // # of confs to wait between deployments. (default: 0)
        timeoutBlocks: 10,  // # of blocks before a deployment times out  (minimum/default: 50)
        skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    hmy_test: {
        provider: () => new HDWalletProvider(PRIKEY, "https://api.s0.b.hmny.io"),
        network_id: '1666700000',       // Any network (default: none)
        skipDryRun: true,
    },
    hmy_main: {
        provider: () => new HDWalletProvider(PRIKEY, "https://api.s0.t.hmny.io"),
        network_id: '1666600000',       // Any network (default: none)
        skipDryRun: true,
    },
    fdr_test: {
        provider: () => new HDWalletProvider(PRIKEY, "https://dev-evm.dev.findora.org:8545"),
        network_id: '523',       // Any network (default: none)
        skipDryRun: true,
        gas: 10000000,
        gasPrice: 1000000000000, // 1000 gwei
    },
    kovan: {
        provider: () => new HDWalletProvider(PRIKEY, "https://kovan.infura.io/v3/d4e15ba154584226bdcba2f1e3ccdbde"),
        network_id: '42',       // Any network (default: none)
        skipDryRun: true,
    },
    rinkeby: {
        provider: () => new HDWalletProvider(PRIKEY, "https://rinkeby.infura.io/v3/d4e15ba154584226bdcba2f1e3ccdbde"),
        network_id: '4',       // Any network (default: none)
        skipDryRun: true,
    },
    develop: {
        host: "127.0.0.1",
        port: 8545,
        network_id: '*',
        accounts: 5,
        defaultEtherBalance: 500,
        blockTime: 0
    },
}