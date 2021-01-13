const MultiSigWallet = artifacts.require("MultiSigWallet");
const Factory = artifacts.require("Factory");

module.exports = async function (deployer, _network, accounts) {
  const owners = accounts.slice(0, 3);
  const required = 3;
  await deployer.deploy(MultiSigWallet, owners, required);
  await deployer.deploy(Factory);
};
