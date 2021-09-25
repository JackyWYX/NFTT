const fs = require('fs');

function toAbi(name) {
    const contract = artifacts.require(name);
    fs.writeFileSync(`./abis/${name}.json`, JSON.stringify(contract.abi))
}

async function main() {
    ['DerivativeFactory', 'Derivative', 'IPPool', 'Licenser', 'MockNFT'].forEach(toAbi); 
}

module.exports = async function (cbk) {
    return main().then(cbk).catch(cbk);
}