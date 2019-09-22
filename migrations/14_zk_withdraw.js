const ZkWithdraw = artifacts.require('WithdrawVerifier')

module.exports = function(deployer) {
  deployer.deploy(ZkWithdraw);
};
