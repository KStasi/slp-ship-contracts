const WrappedSLP = artifacts.require("WrappedSLP");
const Factory = artifacts.require("Factory");

module.exports = async function (deployer, network) {
  if (network == "mainnet") return;
  const factoryInstance = await Factory.deployed();
  await deployer.deploy(WrappedSLP, "slp", "symbol", "name", 0);
  await factoryInstance.createWslp(
    "ff1b54b2141f81e07e0027d369db6484dea8d94429a635c35d17a7462a659239",
    "ZAPT",
    "Zapit",
    0
  );
  await factoryInstance.createWslp(
    "46d85a685ce8d5c983ca24e54379cf19aceeb4878144cd5047007e2f5c172c23",
    "INC",
    "InstaCrypto",
    2
  );
};
