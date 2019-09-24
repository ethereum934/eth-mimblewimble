const ZkDeposit = artifacts.require('DepositVerifier')
const ZkMMRInclusion = artifacts.require('MMRInclusionVerifier')
const ZkMimblewimble = artifacts.require('MimblewimbleVerifier')
const ZkRangeProof = artifacts.require('RangeProofVerifier')
const ZkWithdraw = artifacts.require('WithdrawVerifier')
const ZkRollUp2 = artifacts.require('RollUp2Verifier')
const ZkRollUp4 = artifacts.require('RollUp4Verifier')
const ZkRollUp8 = artifacts.require('RollUp8Verifier')
const ZkRollUp16 = artifacts.require('RollUp16Verifier')
const ZkRollUp32 = artifacts.require('RollUp32Verifier')
const ZkRollUp64 = artifacts.require('RollUp64Verifier')

const chai = require('chai')
const BN = web3.utils.BN
chai.use(require('chai-bn')(web3.utils.BN))
chai.use(require('chai-as-promised'))
chai.should()
const depositProof = require('./dataset/zkSNARKs/deposit')
const mimblewimbleProof = require('./dataset/zkSNARKs/mimblewimble')
const mmrInclusionProof = require('./dataset/zkSNARKs/inclusion')
const rangeProof = require('./dataset/zkSNARKs/range')
const rollUp2Proof = require('./dataset/zkSNARKs/rollUp2')
const rollUp4Proof = require('./dataset/zkSNARKs/rollUp4')
const rollUp8Proof = require('./dataset/zkSNARKs/rollUp8')
const rollUp16Proof = require('./dataset/zkSNARKs/rollUp16')
const rollUp32Proof = require('./dataset/zkSNARKs/rollUp32')
const rollUp64Proof = require('./dataset/zkSNARKs/rollUp64')
const withdrawProof = require('./dataset/zkSNARKs/withdraw')

/**
 */
contract('ZkInterfaces', async ([...users]) => {
  let verifier
  let dataset
  it('Deposit proof', async () => {
    verifier = await ZkDeposit.deployed()
    dataset = depositProof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Range proof', async () => {
    verifier = await ZkRangeProof.deployed()
    dataset = rangeProof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Inclusion proof', async () => {
    verifier = await ZkMMRInclusion.deployed()
    dataset = mmrInclusionProof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Mimblewimble proof', async () => {
    verifier = await ZkMimblewimble.deployed()
    dataset = mimblewimbleProof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Roll Up 2 items to the Pedersen Merkle Mountain Range', async () => {
    verifier = await ZkRollUp2.deployed()
    dataset = rollUp2Proof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Roll Up 4 items to the Pedersen Merkle Mountain Range', async () => {
    verifier = await ZkRollUp4.deployed()
    dataset = rollUp4Proof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Roll Up 8 items to the Pedersen Merkle Mountain Range', async () => {
    verifier = await ZkRollUp8.deployed()
    dataset = rollUp8Proof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Roll Up 16 items to the Pedersen Merkle Mountain Range', async () => {
    verifier = await ZkRollUp16.deployed()
    dataset = rollUp16Proof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Roll Up 32 items to the Pedersen Merkle Mountain Range', async () => {
    verifier = await ZkRollUp32.deployed()
    dataset = rollUp32Proof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Roll Up 64 items to the Pedersen Merkle Mountain Range', async () => {
    verifier = await ZkRollUp64.deployed()
    dataset = rollUp64Proof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
  it('Withdraw proof', async () => {
    verifier = await ZkWithdraw.deployed()
    dataset = withdrawProof
    await verifier.verifyTx(dataset.proof.a, dataset.proof.b, dataset.proof.c, dataset.inputs)
  })
})
