const DerivativeFactory = artifacts.require("DerivativeFactory");
const Derivative = artifacts.require("Derivative");
const IPPool = artifacts.require("IPPool");
const Licenser = artifacts.require("Licenser");
const MockNFT = artifacts.require("MockNFT");
const fs = require('fs');

async function deploy() {
    const factory = await DerivativeFactory.new();
    const ippool = await IPPool.at(await factory.ippool());
    const licenser = await Licenser.at(await factory.licenser());
    console.log('factory:', factory.address);
    console.log('ippool:', ippool.address);
    console.log('licenser:', licenser.address);
    return { factory, ippool, licenser };
}

async function deployMockAPE() {
    const mockApe = await MockNFT.new();
    return mockApe;
}

async function deposit(ippool, token, tokenId) {
    await token.approve(ippool.address, tokenId);
    await ippool.deposit(token.address, tokenId);
}

async function withdraw(ippool, token, tokenId) {
    await ippool.withdraw(token.address, tokenId);
}

async function registerService(factory, recipient, name, symbol, description) {
    const r = await factory.register(recipient, name, symbol, description);
    const registerLog = r.logs.find(log => log.event == 'Register');
    return {
        serviceId: Number(registerLog.args.serviceId),
        derivative: await Derivative.at(registerLog.args.derivative)
    }
}

async function place_order(factory, token, tokenId, serviceId) {
    const r = await factory.place_order(token.address, tokenId, serviceId);
    const placeOrderLog = r.logs.find(log => log.event == 'PlaceOrder');
    console.log('orderId:', Number(placeOrderLog.args.orderId))
    return Number(placeOrderLog.args.orderId);
}

async function complete_order(factory, orderId) {
    console.log(orderId)
    const r = await factory.complete_order(orderId);
    const completeOrderLog = r.logs.find(log => log.event == 'CompleteOrder');
    console.log('licencseId:', completeOrderLog.args.licenseId.toString('hex'));
    return completeOrderLog.args.licenseId;
}

async function add_delivery(factory, orderId, tokenURI) {
    const r = await factory.add_delivery(orderId, tokenURI);
    const deliveryLog = r.logs.find(log => log.event == 'AddDelivery');
    console.log('derivativeTokenId:', Number(deliveryLog.args.derivativeTokenId))
    return {
        orderId: Number(deliveryLog.args.orderId),
        derivative: await Derivative.at(deliveryLog.args.derivativeContract),
        derivativeTokenId: deliveryLog.args.derivativeTokenId
    }
}

const TesterAddress = [
    '0x7A6Ed0a905053A21C15cB5b4F39b561B6A3FE50f'
]

async function faucetETH() {
    const chainId = await web3.eth.getChainId();
    if (chainId == 1337) { // 1337 is local test evm
        const accounts = await web3.eth.getAccounts();
        for(let i = 0; i < TesterAddress.length; i++) {
            const tester = TesterAddress[i];
            const value = web3.utils.toWei("1");
            console.log('send eth to:', tester)
            await web3.eth.sendTransaction({ from:accounts[0], to: tester, value });
        }
    }
}

async function main() {
    const accounts = await web3.eth.getAccounts();
    console.log('accounts:', accounts);
    const chainId = await web3.eth.getChainId();
    console.log('chainId:', chainId);

    const { factory, ippool, licenser } = await deploy();

    const apeId = 1234;
    const mockApe = await deployMockAPE();

    await mockApe.mint(accounts[0], apeId);
    await deposit(ippool, mockApe, apeId);
    //await withdraw(ippool, mockApe, apeId);
    //await deposit(ippool, mockApe, apeId);
    const { serviceId, derivative } = await registerService(factory, accounts[0], "vtuber", "vtuber", "vtuber demo")

    const orderId = await place_order(factory, mockApe, apeId, serviceId);
    const {derivativeTokenId} = await add_delivery(factory, orderId, `https://xxxx/superAPE/xxx`);
    const licencseId = await complete_order(factory, orderId);
    console.log(await factory.get_orders())

    const addressFile = './addresses.json';
    const addresses = fs.existsSync(addressFile)?require(addressFile):{}
    addresses[chainId] = {
        DerivativeFactory: factory.address,
        IPPool: ippool.address,
        Licenser: licenser.address,
        Derivatives: [derivative.address],
        MockNFT: mockApe.address
    }
    fs.writeFileSync('./addresses.json', JSON.stringify(addresses, undefined, '    '))
    chainId == 1337 && await faucetETH();
}

module.exports = async function (cbk) {
    return main().then(cbk).catch(cbk);
}