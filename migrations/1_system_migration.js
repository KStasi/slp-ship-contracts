const MultiSigWallet = artifacts.require("MultiSigWallet");
const Factory = artifacts.require("Factory");

module.exports = async function (deployer, network, accounts) {
  const owners =
    network == "development"
      ? accounts.slice(0, 3)
      : [
          "0x7f52263135780B62f704bec12f4cE1514ba9c377",
          "0xa18f1C76411293EbC166689a76c1A5120E1Bd667",
          "0xbAbB47E7AEec257496283a8bF68B7314934860E9",
        ];
  const required = 3;
  await deployer.deploy(MultiSigWallet, owners, required);
  await deployer.deploy(Factory);
};
