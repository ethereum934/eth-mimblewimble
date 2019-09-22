const ZkRollUp1 = artifacts.require('RollUp1Verifier')

module.exports = function(deployer) {
  deployer.deploy(ZkRollUp1);
};
