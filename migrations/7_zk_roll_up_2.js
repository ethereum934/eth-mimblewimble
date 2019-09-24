const ZkRollUp2 = artifacts.require('RollUp2Verifier')

module.exports = function(deployer) {
  deployer.deploy(ZkRollUp2, {overwrite: false});
};
