const ZkDeposit = artifacts.require('DepositVerifier')

module.exports = function(deployer) {
  deployer.deploy(ZkDeposit, {overwrite: false});
};
