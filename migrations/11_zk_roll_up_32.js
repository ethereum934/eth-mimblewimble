const ZkRollUp32 = artifacts.require('RollUp32Verifier')

module.exports = function(deployer) {
  deployer.deploy(ZkRollUp32);
};
