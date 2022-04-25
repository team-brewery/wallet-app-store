/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@shardlabs/starknet-hardhat-plugin");

module.exports = {
  paths: {
    // Defaults to "contracts" (the same as `paths.sources`).
    starknetSources: "src",
  },
  starknet: {
    venv: "active",
    network: "hack",
    wallets: {
      OpenZeppelin: {
        accountName: "OpenZeppelin",
        modulePath:
          "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount",
        accountPath: "~/.starknet_accounts",
      },
    },
  },
  networks: {
    hack: {
      url: "http://hackathon-5.starknet.io/",
    },
  },
};
