let HDWalletProvider = require("@truffle/hdwallet-provider")
require('dotenv').config()

const provider = new HDWalletProvider(
    process.env.PRIVATE_KEY,
    'https://eth-goerli.g.alchemy.com/v2/Xx9_Sqddd-YRkHPeirhi4SXxoMNHaiCc'
)

const Web3 = require('web3');
const web3 = new Web3(provider);

const contractData = require('../misc/Hasher.json')

const contractAbi = contractData.abi;
const contractBytecode = contractData.bytecode;
const contract = new web3.eth.Contract(contractAbi);

async function main() {
    const account = await web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);


    const gasFee = await contract.deploy({
        data: '0x' + contractBytecode
    }).estimateGas({
        from: account.address
    })
    const result = await contract.deploy({
        data: contractBytecode
    }).send({
        from: account.address,
        gas: gasFee
    });
    console.log(result.options.address);


    process.exit()
};

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
    process.exit()
})
