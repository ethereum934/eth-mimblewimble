const ZkRollUp16 = artifacts.require('RollUp16Verifier')

module.exports = function(deployer) {
  deployer.deploy(ZkRollUp16, {overwrite: false});
};
