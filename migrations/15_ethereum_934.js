const Ethereum934 = artifacts.require('Ethereum934')
const ZkDeposit = artifacts.require('DepositVerifier')
const ZkRangeProof = artifacts.require('RangeProofVerifier')
const ZkMimblewimble = artifacts.require('MimblewimbleVerifier')
const ZkMMRInclusion = artifacts.require('MMRInclusionVerifier')
const ZkRollUp1 = artifacts.require('RollUp1Verifier')
const ZkRollUp2 = artifacts.require('RollUp2Verifier')
const ZkRollUp4 = artifacts.require('RollUp4Verifier')
const ZkRollUp8 = artifacts.require('RollUp8Verifier')
const ZkRollUp16 = artifacts.require('RollUp16Verifier')
const ZkRollUp32 = artifacts.require('RollUp32Verifier')
const ZkRollUp64 = artifacts.require('RollUp64Verifier')
const ZkWithdraw = artifacts.require('WithdrawVerifier')

module.exports = function (deployer) {
  deployer.deploy(Ethereum934,
    ZkDeposit.address,
    ZkRangeProof.address,
    ZkMimblewimble.address,
    ZkMMRInclusion.address,
    ZkRollUp1.address,
    ZkRollUp2.address,
    ZkRollUp4.address,
    ZkRollUp8.address,
    ZkRollUp16.address,
    ZkRollUp32.address,
    ZkRollUp64.address,
    ZkWithdraw.address,
  )
}
