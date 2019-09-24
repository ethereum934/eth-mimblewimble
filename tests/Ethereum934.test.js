const assert = require('assert');
const chai = require('chai')
const BN = web3.utils.BN
chai.use(require('chai-bn')(web3.utils.BN))
chai.use(require('chai-as-promised'))
chai.should()
const Ethereum934 = artifacts.require('Ethereum934')
const ERC20 = artifacts.require('EthGalleon')
const deposit1 = require('./dataset/ethereum934/deposit1')
const deposit2 = require('./dataset/ethereum934/deposit2')
const tx1 = require('./dataset/ethereum934/tx1')
const tx2 = require('./dataset/ethereum934/tx2')
const tx3 = require('./dataset/ethereum934/tx3')
const tx4 = require('./dataset/ethereum934/tx4')
const tx5 = require('./dataset/ethereum934/tx5')
const tx6 = require('./dataset/ethereum934/tx6')
const tx7 = require('./dataset/ethereum934/tx7')
const tx8 = require('./dataset/ethereum934/tx8')
const tx9 = require('./dataset/ethereum934/tx9')
const tx10 = require('./dataset/ethereum934/tx10')
const tx11 = require('./dataset/ethereum934/tx11')
const tx12 = require('./dataset/ethereum934/tx12')
const tx13 = require('./dataset/ethereum934/tx13')
const tx14 = require('./dataset/ethereum934/tx14')
const tx15 = require('./dataset/ethereum934/tx15')
const tx16 = require('./dataset/ethereum934/tx16')
const tx17 = require('./dataset/ethereum934/tx17')
const tx18 = require('./dataset/ethereum934/tx18')
const tx19 = require('./dataset/ethereum934/tx19')
const tx20 = require('./dataset/ethereum934/tx20')
const tx21 = require('./dataset/ethereum934/tx21')
const tx22 = require('./dataset/ethereum934/tx22')
const tx23 = require('./dataset/ethereum934/tx23')
const tx24 = require('./dataset/ethereum934/tx24')
const tx25 = require('./dataset/ethereum934/tx25')
const tx26 = require('./dataset/ethereum934/tx26')
const tx27 = require('./dataset/ethereum934/tx27')
const tx28 = require('./dataset/ethereum934/tx28')
const tx29 = require('./dataset/ethereum934/tx29')
const tx30 = require('./dataset/ethereum934/tx30')
const tx31 = require('./dataset/ethereum934/tx31')
const tx32 = require('./dataset/ethereum934/tx32')
const tx33 = require('./dataset/ethereum934/tx33')
const tx34 = require('./dataset/ethereum934/tx34')
const tx35 = require('./dataset/ethereum934/tx35')
const tx36 = require('./dataset/ethereum934/tx36')
const tx37 = require('./dataset/ethereum934/tx37')
const tx38 = require('./dataset/ethereum934/tx38')
const tx39 = require('./dataset/ethereum934/tx39')
const tx40 = require('./dataset/ethereum934/tx40')
const tx41 = require('./dataset/ethereum934/tx41')
const tx42 = require('./dataset/ethereum934/tx42')
const tx43 = require('./dataset/ethereum934/tx43')
const tx44 = require('./dataset/ethereum934/tx44')
const tx45 = require('./dataset/ethereum934/tx45')
const tx46 = require('./dataset/ethereum934/tx46')
const tx47 = require('./dataset/ethereum934/tx47')
const tx48 = require('./dataset/ethereum934/tx48')
const tx49 = require('./dataset/ethereum934/tx49')
const tx50 = require('./dataset/ethereum934/tx50')
const tx51 = require('./dataset/ethereum934/tx51')
const tx52 = require('./dataset/ethereum934/tx52')
const tx53 = require('./dataset/ethereum934/tx53')
const tx54 = require('./dataset/ethereum934/tx54')
const tx55 = require('./dataset/ethereum934/tx55')
const tx56 = require('./dataset/ethereum934/tx56')
const tx57 = require('./dataset/ethereum934/tx57')
const tx58 = require('./dataset/ethereum934/tx58')
const tx59 = require('./dataset/ethereum934/tx59')
const tx60 = require('./dataset/ethereum934/tx60')
const tx61 = require('./dataset/ethereum934/tx61')
const tx62 = require('./dataset/ethereum934/tx62')
const tx63 = require('./dataset/ethereum934/tx63')
const tx64 = require('./dataset/ethereum934/tx64')
const tx65 = require('./dataset/ethereum934/tx65')
const tx66 = require('./dataset/ethereum934/tx66')
const tx67 = require('./dataset/ethereum934/tx67')
const tx68 = require('./dataset/ethereum934/tx68')
const rollUp1 = require('./dataset/ethereum934/rollUp1')
const rollUp2 = require('./dataset/ethereum934/rollUp2')
const rollUp3 = require('./dataset/ethereum934/rollUp3')
const rollUp4 = require('./dataset/ethereum934/rollUp4')
const rollUp5 = require('./dataset/ethereum934/rollUp5')
const rollUp6 = require('./dataset/ethereum934/rollUp6')
const rollUp7 = require('./dataset/ethereum934/rollUp7')
const rollUp8 = require('./dataset/ethereum934/rollUp8')
const rollUp9 = require('./dataset/ethereum934/rollUp9')
const withdrawProof = require('./dataset/ethereum934/withdraw')
const doubleSpendingInclusion = require('./dataset/ethereum934/doubleSpendingInclusion')
const doubleSpendingWithdraw = require('./dataset/ethereum934/doubleSpendingWithdraw')

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
  let relayer = users[1]
  let alice = users[2]
  let bob = users[3]
  let carl = users[4]
  before('Create and allocate ERC20 tokens', async () => {
    erc20 = await ERC20.new({ from: god })
    ethereum934 = await Ethereum934.deployed()
    assert(erc20.address === '0xACa6BFcc686ED93b5aa5820d5A7B7B82513c106c', 'Testing purpose ERC20 address has been changed. You need to make a new test data set')
    await erc20.mint(alice, web3.utils.toWei(new BN(10000)), { from: god })
    await erc20.mint(bob, web3.utils.toWei(new BN(10000)), { from: god })
    await erc20.approve(ethereum934.address, web3.utils.toWei(new BN(1000000)), { from: alice })
    await erc20.approve(ethereum934.address, web3.utils.toWei(new BN(1000000)), { from: bob })
  })
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
        rollUp1.inputs[rollUp1.inputs.length - 2],
        [flattenTx(tx1), flattenTx(tx2)],
        flattenProof(rollUp1.proof),
        { from: relayer }
      )
    })
    it('Round 2: roll up 2 Mimblewimble txs spending 2 hidden TXOs and 1 hidden TXO.', async () => {
      await ethereum934.rollUp2Mimblewimble(
        erc20.address,
        rollUp2.inputs[0],
        rollUp2.inputs[rollUp2.inputs.length - 2],
        [flattenTx(tx3), flattenTx(tx4)],
        flattenProof(rollUp2.proof),
        { from: relayer }
      )
    })
    it('Round 3: roll up 2 Mimblewimble txs spending 2 hidden TXOs for each.', async () => {
      await ethereum934.rollUp2Mimblewimble(
        erc20.address,
        rollUp3.inputs[0],
        rollUp3.inputs[rollUp3.inputs.length - 2],
        [flattenTx(tx5), flattenTx(tx6)],
        flattenProof(rollUp3.proof),
        { from: relayer }
      )
    })
    it('Round 4: roll up 1 Mimblewimble tx spending 1 hidden TXO.', async () => {
      await ethereum934.rollUp1Mimblewimble(
        erc20.address,
        rollUp4.inputs[0],
        rollUp4.inputs[rollUp4.inputs.length - 2],
        [flattenTx(tx7)],
        flattenProof(rollUp4.proof),
        { from: relayer }
      )
    })
    it('Round 5: roll up 1 Mimblewimble tx spending 2 hidden TXOs.', async () => {
      await ethereum934.rollUp1Mimblewimble(
        erc20.address,
        rollUp5.inputs[0],
        rollUp5.inputs[rollUp5.inputs.length - 2],
        [flattenTx(tx8)],
        flattenProof(rollUp5.proof),
        { from: relayer }
      )
    })
  })
  describe('optimisticRollUp()', async () => {
    it('Round 6: optimistic roll up 4 Mimblewimble transactions.', async () => {
      let result = await ethereum934.optimisticRollUpMimblewimble(
        erc20.address,
        rollUp6.inputs[0],
        rollUp6.inputs[rollUp6.inputs.length - 2],
        [tx9, tx10, tx11, tx12].map((tx) => flattenTx(tx)),
        flattenProof(rollUp6.proof),
        { from: relayer }
      )
      let id = result.logs[0].args.id
      await ethereum934.finalizeRollUp(id)
    })
    it('Round 7: optimistic roll up 8 Mimblewimble transactions.', async () => {
      let result = await ethereum934.optimisticRollUpMimblewimble(
        erc20.address,
        rollUp7.inputs[0],
        rollUp7.inputs[rollUp7.inputs.length - 2],
        [tx13, tx14, tx15, tx16, tx17, tx18, tx19, tx20].map((tx) => flattenTx(tx)),
        flattenProof(rollUp7.proof),
        { from: relayer }
      )
      let id = result.logs[0].args.id
      await ethereum934.finalizeRollUp(id)
    })
    it('Round 8: optimistic roll up 16 Mimblewimble transactions.', async () => {
      let result = await ethereum934.optimisticRollUpMimblewimble(
        erc20.address,
        rollUp8.inputs[0],
        rollUp8.inputs[rollUp8.inputs.length - 2],
        [
          tx21, tx22, tx23, tx24, tx25, tx26, tx27, tx28,
          tx29, tx30, tx31, tx32, tx33, tx34, tx35, tx36,
        ].map((tx) => flattenTx(tx)),
        flattenProof(rollUp8.proof),
        { from: relayer }
      )
      let id = result.logs[0].args.id
      await ethereum934.finalizeRollUp(id)
    })
    it('Round 9: optimistic roll up 32 Mimblewimble transactions.', async () => {
      let result = await ethereum934.optimisticRollUpMimblewimble(
        erc20.address,
        rollUp9.inputs[0],
        rollUp9.inputs[rollUp9.inputs.length - 2],
        [
          tx37, tx38, tx39, tx40, tx41, tx42, tx43, tx44,
          tx45, tx46, tx47, tx48, tx49, tx50, tx51, tx52,
          tx53, tx54, tx55, tx56, tx57, tx58, tx59, tx60,
          tx61, tx62, tx63, tx64, tx65, tx66, tx67, tx68,
        ].map((tx) => flattenTx(tx)),
        flattenProof(rollUp9.proof),
        { from: relayer }
      )
      let id = result.logs[0].args.id
      await ethereum934.finalizeRollUp(id)
    })
  })
  describe('withdraw()', async () => {
    it('should prevent double spending.', (done) => {
      // Deposit ERC20 token to the magical world
      ethereum934.withdrawToMuggleWorld(
        erc20.address,
        doubleSpendingWithdraw.inputs[1], // tag
        doubleSpendingWithdraw.inputs[2], // value
        doubleSpendingWithdraw.inputs[0], // root
        doubleSpendingWithdraw.proof.a,
        doubleSpendingWithdraw.proof.b,
        doubleSpendingWithdraw.proof.c,
        { from: carl }
      ).should.be.rejected.and.notify(done)
    })
    it('should withdraw ERC20 with zk proof spending a hidden TXO.', async () => {
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
