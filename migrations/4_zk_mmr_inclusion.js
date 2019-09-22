const ZkMMRInclusion = artifacts.require('MMRInclusionVerifier')

module.exports = function(deployer) {
  deployer.deploy(ZkMMRInclusion);
};
