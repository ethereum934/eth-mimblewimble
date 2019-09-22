const ZkRollUp64 = artifacts.require('RollUp64Verifier')

module.exports = function(deployer) {
  deployer.deploy(ZkRollUp64);
};
