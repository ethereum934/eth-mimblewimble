const ZkRollUp4 = artifacts.require('RollUp4Verifier')

module.exports = function(deployer) {
  deployer.deploy(ZkRollUp4, {overwrite: false});
};
