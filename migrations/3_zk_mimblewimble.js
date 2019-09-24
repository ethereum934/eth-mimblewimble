const ZkMimblewimble = artifacts.require('MimblewimbleVerifier')

module.exports = function(deployer) {
  deployer.deploy(ZkMimblewimble, {overwrite: false});
};
