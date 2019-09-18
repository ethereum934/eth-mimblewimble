const Ethereum934 = artifacts.require('Ethereum934');
const ZkDeposit = artifacts.require('ZkDeposit');
const ZkMimblewimble = artifacts.require('ZkMimblewimble');
const ZkMMRInclusion = artifacts.require('ZkMMRInclusion');
const ZkRangeProof = artifacts.require('ZkRangeProof');
const ZkRollUp1 = artifacts.require('ZkRollUp1');
const ZkRollUp2 = artifacts.require('ZkRollUp2');
const ZkRollUp4 = artifacts.require('ZkRollUp4');
const ZkRollUp8 = artifacts.require('ZkRollUp8');
const ZkRollUp16 = artifacts.require('ZkRollUp16');
const ZkWithdraw = artifacts.require('ZkWithdraw');

const ERC20 = artifacts.require('EthGalleon');
const chai = require('chai');
const BN = web3.utils.BN;
chai.use(require('chai-bn')(web3.utils.BN));
chai.use(require('chai-as-promised'));
chai.should();
const deposit = require('./dataset/deposit_proof');
const transaction = require('./dataset/transaction');

/**
 */
contract('Ethereum934', async ([...users]) => {
  let erc20;
  let ethereum934;
  before('Create and allocate ERC20 tokens', async () => {
    console.log(transaction);
    erc20 = await ERC20.new({ from: users[0] });
    zkDeposit = await ZkDeposit.new();
    zkMimblewimble = await ZkMimblewimble.new();
    zkMMRInclusion = await ZkMMRInclusion.new();
    zkRangeProof = await ZkRangeProof.new();
    zkRollUp1 = await ZkRollUp1.new();
    zkRollUp2 = await ZkRollUp2.new();
    zkRollUp4 = await ZkRollUp4.new();
    zkRollUp8 = await ZkRollUp8.new();
    zkRollUp16 = await ZkRollUp16.new();
    zkWithdraw = await ZkWithdraw.new();
    console.log(zkWithdraw.address);
    ethereum934 = await Ethereum934.new(
      zkDeposit.address,
      zkMimblewimble.address,
      zkMMRInclusion.address,
      zkRangeProof.address,
      zkRollUp1.address,
      zkRollUp2.address,
      zkRollUp4.address,
      zkRollUp8.address,
      zkRollUp16.address,
      zkWithdraw.address
    );

    await erc20.mint(users[1], web3.utils.toWei(new BN(10000)), {
      from: users[0]
    });
    await erc20.approve(ethereum934.address, web3.utils.toWei(new BN(1000000)), {
      from: users[1]
    });
  });
  context('Deposit', async () => {
    describe('deposit()', async () => {
      it('Deposit with TXO', async () => {
        let txoY = deposit.inputs[0];
        let value = deposit.inputs[1]; // 2347
        let a = deposit.proof.a;
        let b = deposit.proof.b;
        let c = deposit.proof.c;
        // Deposit ERC20 token to the magical world
        await ethereum934.depositToMagicalWorld(erc20.address, txoY, value, a, b, c, { from: users[1] });
        let depositedBalance = await erc20.balanceOf(ethereum934.address);
        // Successfully deposited!
        depositedBalance.should.be.a.bignumber.that.equals('2347');
      });
    });
    describe('rollUp()', async () => {
      let currentRoot = 1;
    });
  });
});
