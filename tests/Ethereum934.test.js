const Ethereum934 = artifacts.require('Ethereum934')
const ZkDeposit = artifacts.require('ZkDeposit')
const ZkMimblewimble = artifacts.require('ZkMimblewimble')
const ZkMMRInclusion = artifacts.require('ZkMMRInclusion')
const ZkRangeProof = artifacts.require('ZkRangeProof')
const ZkRollUp1 = artifacts.require('ZkRollUp1')
const ZkRollUp2 = artifacts.require('ZkRollUp2')
const ZkRollUp4 = artifacts.require('ZkRollUp4')
const ZkRollUp8 = artifacts.require('ZkRollUp8')
const ZkRollUp16 = artifacts.require('ZkRollUp16')
const ZkWithdraw = artifacts.require('ZkWithdraw')

const ERC20 = artifacts.require('EthGalleon')
const chai = require('chai')
const BN = web3.utils.BN
chai.use(require('chai-bn')(web3.utils.BN))
chai.use(require('chai-as-promised'))
chai.should()
const deposit1 = require('./dataset/deposit1')
const deposit2 = require('./dataset/deposit2')
const tx1 = require('./dataset/tx1')
const tx2 = require('./dataset/tx2')
const tx3 = require('./dataset/tx3')
const tx4 = require('./dataset/tx4')
const tx5 = require('./dataset/tx5')
const tx6 = require('./dataset/tx6')
const tx7 = require('./dataset/tx7')
const tx8 = require('./dataset/tx8')
const rollUp1 = require('./dataset/rollUp1')
const rollUp2 = require('./dataset/rollUp2')
const rollUp3 = require('./dataset/rollUp3')
const rollUp4 = require('./dataset/rollUp4')
const rollUp5 = require('./dataset/rollUp5')
const inclusionProofForWithdraw = require('./dataset/inclusion')
const withdrawProof = require('./dataset/withdraw')

function flattenDeep (arr1) {
  return arr1.reduce((acc, val) => Array.isArray(val) ? acc.concat(flattenDeep(val)) : acc.concat(val), [])
}

function flattenProof (proof) {
  return [...proof.a, ...flattenDeep(proof.b), ...proof.c]
}

function flattenTx (tx) {
  let mwTx = [
    tx.kernel.fee,
    tx.kernel.metadata,
    tx.body.hh_input_tags[0],
    tx.inclusion_proofs[0] == null ? web3.utils.leftPad(1, 64) : tx.inclusion_proofs[0].inputs[0],
    tx.inclusion_proofs[0] == null ? Array(8).fill(web3.utils.leftPad(0, 64)) : flattenProof(tx.inclusion_proofs[0].proof),
    tx.body.hh_input_tags[1],
    tx.inclusion_proofs[1] == null ? web3.utils.leftPad(1, 64) : tx.inclusion_proofs[1].inputs[0],
    tx.inclusion_proofs[1] == null ? Array(8).fill(web3.utils.leftPad(0, 64)) : flattenProof(tx.inclusion_proofs[1].proof),
    tx.body.hh_outputs[0],
    flattenProof(tx.range_proofs[0].proof),
    tx.body.hh_outputs[1],
    flattenProof(tx.range_proofs[1].proof),
    tx.kernel.signature.R,
    flattenProof(tx.mimblewimble_proof.proof)]
  return flattenDeep(mwTx)
}

/**
 */
contract('Ethereum934', async ([...users]) => {
  let erc20
  let ethereum934
  let god = users[0]
  let alice = users[1]
  let bob = users[2]
  let carl = users[3]
  before('Create and allocate ERC20 tokens', async () => {
    erc20 = await ERC20.new({ from: god })
    zkDeposit = await ZkDeposit.new()
    zkMimblewimble = await ZkMimblewimble.new()
    zkMMRInclusion = await ZkMMRInclusion.new()
    zkRangeProof = await ZkRangeProof.new()
    zkRollUp1 = await ZkRollUp1.new()
    zkRollUp2 = await ZkRollUp2.new()
    zkRollUp4 = await ZkRollUp4.new()
    zkRollUp8 = await ZkRollUp8.new()
    zkRollUp16 = await ZkRollUp16.new()
    zkWithdraw = await ZkWithdraw.new()
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
      zkWithdraw.address
    )

    await erc20.mint(alice, web3.utils.toWei(new BN(10000)), { from: god })
    await erc20.mint(bob, web3.utils.toWei(new BN(10000)), { from: god })
    await erc20.approve(ethereum934.address, web3.utils.toWei(new BN(1000000)), { from: alice })
    await erc20.approve(ethereum934.address, web3.utils.toWei(new BN(1000000)), { from: bob })
  })
  context('Deposit', async () => {
    describe('deposit()', async () => {
      it('Deposit ERC20 and create the first coinbase.', async () => {
        // Deposit ERC20 token to the magical world
        await ethereum934.depositToMagicalWorld(
          erc20.address,
          deposit1.inputs[0],
          deposit1.inputs[1],
          deposit1.proof.a,
          deposit1.proof.b,
          deposit1.proof.c,
          { from: alice }
        )
        let depositedBalance1 = await erc20.balanceOf(ethereum934.address)
        let expected1 = `${web3.utils.hexToNumber(deposit1.inputs[1])}`
        depositedBalance1.should.be.a.bignumber.that.equals(expected1)
      })
      it('Deposit ERC20 and create the second coinbase.', async () => {
        // Deposit ERC20 token to the magical world
        await ethereum934.depositToMagicalWorld(
          erc20.address,
          deposit2.inputs[0],
          deposit2.inputs[1],
          deposit2.proof.a,
          deposit2.proof.b,
          deposit2.proof.c,
          { from: bob }
        )
        let depositedBalance2 = await erc20.balanceOf(ethereum934.address)
        let expected2 = `${web3.utils.hexToNumber(deposit2.inputs[1]) + web3.utils.hexToNumber(deposit1.inputs[1])}`
        depositedBalance2.should.be.a.bignumber.that.equals(expected2)
      })
    })
    describe('rollUp()', async () => {
      it('Round 1: roll up 2 Mimblewimble txs spending 1 coinbase for each.', async () => {
        await ethereum934.rollUp2Mimblewimble(
          erc20.address,
          rollUp1.inputs[0],
          rollUp1.inputs[10],
          [flattenTx(tx1), flattenTx(tx2)],
          flattenProof(rollUp1.proof)
        )
      })
      it('Round 2: roll up 2 Mimblewimble txs spending 2 hidden TXOs and 1 hidden TXO.', async () => {
        await ethereum934.rollUp2Mimblewimble(
          erc20.address,
          rollUp2.inputs[0],
          rollUp2.inputs[10],
          [flattenTx(tx3), flattenTx(tx4)],
          flattenProof(rollUp2.proof)
        )
      })
      it('Round 3: roll up 2 Mimblewimble txs spending 2 hidden TXOs for each.', async () => {
        await ethereum934.rollUp2Mimblewimble(
          erc20.address,
          rollUp3.inputs[0],
          rollUp3.inputs[10],
          [flattenTx(tx5), flattenTx(tx6)],
          flattenProof(rollUp3.proof)
        )
      })
      it('Round 4: roll up 1 Mimblewimble tx spending 1 hidden TXO.', async () => {
        await ethereum934.rollUp1Mimblewimble(
          erc20.address,
          rollUp4.inputs[0],
          rollUp4.inputs[6],
          [flattenTx(tx7)],
          flattenProof(rollUp4.proof)
        )
      })
      it('Round 5: roll up 1 Mimblewimble tx spending 2 hidden TXOs.', async () => {
        await ethereum934.rollUp1Mimblewimble(
          erc20.address,
          rollUp5.inputs[0],
          rollUp5.inputs[6],
          [flattenTx(tx8)],
          flattenProof(rollUp5.proof)
        )
      })
    })
    describe('withdraw()', async () => {
      it('Withdraw ERC20 with zk proof spending a hidden TXO.', async () => {
        // Deposit ERC20 token to the magical world
        await ethereum934.withdrawToMuggleWorld(
          erc20.address,
          withdrawProof.inputs[1], // tag
          withdrawProof.inputs[2], // value
          withdrawProof.inputs[0], // root
          withdrawProof.proof.a,
          withdrawProof.proof.b,
          withdrawProof.proof.c,
          { from: carl }
        )
        let withdrawn = await erc20.balanceOf(carl)
        let expected = `${web3.utils.hexToNumber(withdrawProof.inputs[2])}`
        withdrawn.should.be.a.bignumber.that.equals(expected)
      })
    })
  })
})
