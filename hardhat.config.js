require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-chai-matchers");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");
require("solidity-coverage");
require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  namedAccounts: {
    deployer: {
      default: 0, // ethers built in account at index 0
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "CIQMG8MEB51SCJJ6W7AMNGIS3MAFV8B6U9",
  },
};
