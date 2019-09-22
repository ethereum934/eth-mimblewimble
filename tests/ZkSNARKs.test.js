const Ethereum934 = artifacts.require('Ethereum934')
const ZkDeposit = artifacts.require('DepositVerifier')
const ZkMimblewimble = artifacts.require('MimblewimbleVerifier')
const ZkMMRInclusion = artifacts.require('MMRInclusionVerifier')
const ZkRangeProof = artifacts.require('RangeProofVerifier')
const ZkRollUp1 = artifacts.require('RollUp1Verifier')
const ZkRollUp2 = artifacts.require('RollUp2Verifier')
const ZkRollUp4 = artifacts.require('RollUp4Verifier')
const ZkRollUp8 = artifacts.require('RollUp8Verifier')
const ZkRollUp16 = artifacts.require('RollUp16Verifier')
const ZkRollUp32 = artifacts.require('RollUp32Verifier')
const ZkRollUp64 = artifacts.require('RollUp64Verifier')
const ZkWithdraw = artifacts.require('WithdrawVerifier')

const ERC20 = artifacts.require('EthGalleon')
const chai = require('chai')
const BN = web3.utils.BN
chai.use(require('chai-bn')(web3.utils.BN))
chai.use(require('chai-as-promised'))
chai.should()
const depositProof = require('./dataset/snarks/deposit')
const mimblewimbleProof = require('./dataset/snarks/mimblewimble')
const mmrInclusionProof = require('./dataset/snarks/mmrInclusion')
const rangeProof = require('./dataset/snarks/rangePoof')
const rollUp1Proof = require('./dataset/snarks/rollUp1')
const rollUp2Proof = require('./dataset/snarks/rollUp2')
const rollUp4Proof = require('./dataset/snarks/rollUp4')
const rollUp8Proof = require('./dataset/snarks/rollUp8')
const rollUp16Proof = require('./dataset/snarks/rollUp16')
const rollUp32Proof = require('./dataset/snarks/rollUp32')
const rollUp64Proof = require('./dataset/snarks/rollUp64')
const withdrawProof = require('./dataset/snarks/withdraw')

/**
 */
contract.skip('ZkInterfaces', async ([...users]) => {
  before('Create and allocate ERC20 tokens', async () => {
    erc20 = await ERC20.new({ from: god })
    zkDeposit = await ZkDeposit.deployed()
    zkMimblewimble = await ZkMimblewimble.deployed()
    zkMMRInclusion = await ZkMMRInclusion.deployed()
    zkRangeProof = await ZkRangeProof.deployed()
    zkRollUp1 = await ZkRollUp1.deployed()
    zkRollUp2 = await ZkRollUp2.deployed()
    zkRollUp4 = await ZkRollUp4.deployed()
    zkRollUp8 = await ZkRollUp8.deployed()
    zkRollUp16 = await ZkRollUp16.deployed()
    zkRollUp32 = await ZkRollUp32.deployed()
    zkRollUp64 = await ZkRollUp64.deployed()
    zkWithdraw = await ZkWithdraw.deployed()
    ethereum934 = await Ethereum934.new(
      zkDeposit.address,
      zkRangeProof.address,
      zkMimblewimble.address,
      zkMMRInclusion.address,
      zkRollUp1.address,
      zkRollUp2.address,
      zkRollUp4.address,
      zkRollUp8.address,
      zkRollUp16.address,
      zkRollUp32.address,
      zkRollUp64.address,
      zkWithdraw.address
    )
  })
  it('should pass', async()=>{

  })
})
