const MultiSigWallet = artifacts.require("MultiSigWallet");
const Factory = artifacts.require("Factory");

module.exports = async function (_deployer) {
  const factoryInstance = await Factory.deployed();
  await factoryInstance.transferOwnership(MultiSigWallet.address);
};
