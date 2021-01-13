const MultiSigWallet = artifacts.require("MultiSigWallet");
const WrappedSLP = artifacts.require("WrappedSLP");

module.exports = async function (_deployer) {
  const wrappedSLPInstance = await WrappedSLP.deployed();
  await wrappedSLPInstance.transferOwnership(MultiSigWallet.address);
};
