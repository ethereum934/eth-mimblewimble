const ZkRangeProof = artifacts.require('RangeProofVerifier')

module.exports = function(deployer) {
  deployer.deploy(ZkRangeProof, {overwrite: false});
};
