from ethsnarks.field import SNARK_SCALAR_FIELD

from py934.mimblewimble import TxSend, Output, Field, TxReceive, Transaction
from py934.mmr import PedersenMMR
import json
import copy
import os

BUILD_PATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'build')


def make_tx(
        input_txo_1: Output,
        inclusion_proof_1,
        input_txo_2: Output,
        inclusion_proof_2
) -> (Transaction, Output, Output):
    fee = Field.random(1, 10)
    input_val = 0
    if input_txo_1 is not None:
        input_val += input_txo_1.v
    if input_txo_2 is not None:
        input_val += input_txo_2.v
    output_val = Field(int(input_val) // 2)
    change_val = input_val - fee - output_val
    output_txo = Output.new(output_val)
    change_txo = Output.new(change_val)
    tx_send = TxSend.builder(). \
        value(output_val). \
        fee(fee). \
        input_txo(input_txo_1, inclusion_proof_1). \
        input_txo(input_txo_2, inclusion_proof_2). \
        change_txo(change_txo). \
        metadata(100). \
        sig_salt(Field.random(1, SNARK_SCALAR_FIELD)). \
        build()
    tx_receive = TxReceive.builder(). \
        request(tx_send). \
        output_txo(output_txo). \
        sig_salt(Field.random(1, SNARK_SCALAR_FIELD)). \
        build()
    tx = tx_send.merge(tx_receive.response)
    return tx, output_txo, change_txo


mmr = PedersenMMR()
root_0 = copy.deepcopy(mmr.root)
width_0 = copy.deepcopy(mmr.width)
peaks_0 = copy.deepcopy(mmr.peaks)

# Deposit
deposit_txo_1 = Output.new(Field.random(1000000, 10000000))
deposit_txo_2 = Output.new(Field.random(1000000, 10000000))
with open(os.path.join(BUILD_PATH, 'deposit1.json'), 'w+') as f:
    json.dump(deposit_txo_1.deposit_proof, f)
with open(os.path.join(BUILD_PATH, 'deposit2.json'), 'w+') as f:
    json.dump(deposit_txo_2.deposit_proof, f)

# Roll up round 1
input_txo_1_1 = deposit_txo_1
input_txo_2_1 = deposit_txo_2
tx_1, output_txo_1_1, output_txo_1_2 = make_tx(input_txo_1_1, None, None, None)
tx_2, output_txo_2_1, output_txo_2_2 = make_tx(input_txo_2_1, None, None, None)

mmr.append(output_txo_1_1.hh)
mmr.append(output_txo_1_2.hh)
mmr.append(output_txo_2_1.hh)
mmr.append(output_txo_2_2.hh)
root_1 = copy.deepcopy(mmr.root)
width_1 = copy.deepcopy(mmr.width)
peaks_1 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx1.json'), 'w+') as f:
    json.dump(tx_1.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx2.json'), 'w+') as f:
    json.dump(tx_2.to_dict(), f)

roll_up_proof_1 = PedersenMMR.zk_roll_up_proof(
    root_0,
    width_0,
    peaks_0,
    [output_txo_1_1.hh, output_txo_1_2.hh, output_txo_2_1.hh, output_txo_2_2.hh],
    root_1
)
with open(os.path.join(BUILD_PATH, 'rollUp1.json'), 'w+') as f:
    json.dump(roll_up_proof_1, f)

# Roll up round 2
input_txo_3_1 = output_txo_1_1
input_txo_4_1 = output_txo_2_1
input_txo_4_2 = output_txo_2_2

input_txo_3_1_inclusion_proof = mmr.get_inclusion_proof(1)
input_txo_4_1_inclusion_proof = mmr.get_inclusion_proof(3)
input_txo_4_2_inclusion_proof = mmr.get_inclusion_proof(4)
zk_inclusion_proof_input_txo_3_1 = input_txo_3_1_inclusion_proof.zk_proof(input_txo_3_1.r, input_txo_3_1.v)
zk_inclusion_proof_input_txo_4_1 = input_txo_4_1_inclusion_proof.zk_proof(input_txo_4_1.r, input_txo_4_1.v)
zk_inclusion_proof_input_txo_4_2 = input_txo_4_2_inclusion_proof.zk_proof(input_txo_4_2.r, input_txo_4_2.v)

tx_3, output_txo_3_1, output_txo_3_2 = make_tx(input_txo_3_1, zk_inclusion_proof_input_txo_3_1, None, None)
tx_4, output_txo_4_1, output_txo_4_2 = make_tx(
    input_txo_4_1,
    zk_inclusion_proof_input_txo_4_1,
    input_txo_4_2,
    zk_inclusion_proof_input_txo_4_2
)

mmr.append(output_txo_3_1.hh)
mmr.append(output_txo_3_2.hh)
mmr.append(output_txo_4_1.hh)
mmr.append(output_txo_4_2.hh)
root_2 = copy.deepcopy(mmr.root)
width_2 = copy.deepcopy(mmr.width)
peaks_2 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx3.json'), 'w+') as f:
    json.dump(tx_3.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx4.json'), 'w+') as f:
    json.dump(tx_4.to_dict(), f)

roll_up_proof_2 = PedersenMMR.zk_roll_up_proof(
    root_1,
    width_1,
    peaks_1,
    [output_txo_3_1.hh, output_txo_3_2.hh, output_txo_4_1.hh, output_txo_4_2.hh],
    root_2
)
with open(os.path.join(BUILD_PATH, 'rollUp2.json'), 'w+') as f:
    json.dump(roll_up_proof_2, f)

# Roll up round 3
input_txo_5_1 = output_txo_1_2
input_txo_5_2 = output_txo_3_1
input_txo_6_1 = output_txo_3_2
input_txo_6_2 = output_txo_4_2

input_txo_5_1_inclusion_proof = mmr.get_inclusion_proof(2)
input_txo_5_2_inclusion_proof = mmr.get_inclusion_proof(5)
input_txo_6_1_inclusion_proof = mmr.get_inclusion_proof(6)
input_txo_6_2_inclusion_proof = mmr.get_inclusion_proof(8)
zk_inclusion_proof_input_txo_5_1 = input_txo_5_1_inclusion_proof.zk_proof(input_txo_5_1.r, input_txo_5_1.v)
zk_inclusion_proof_input_txo_5_2 = input_txo_5_2_inclusion_proof.zk_proof(input_txo_5_2.r, input_txo_5_2.v)
zk_inclusion_proof_input_txo_6_1 = input_txo_6_1_inclusion_proof.zk_proof(input_txo_6_1.r, input_txo_6_1.v)
zk_inclusion_proof_input_txo_6_2 = input_txo_6_2_inclusion_proof.zk_proof(input_txo_6_2.r, input_txo_6_2.v)

tx_5, output_txo_5_1, output_txo_5_2 = make_tx(
    input_txo_5_1, zk_inclusion_proof_input_txo_5_1,
    input_txo_5_2, zk_inclusion_proof_input_txo_5_2
)
tx_6, output_txo_6_1, output_txo_6_2 = make_tx(
    input_txo_6_1, zk_inclusion_proof_input_txo_6_1,
    input_txo_6_2, zk_inclusion_proof_input_txo_6_2
)

mmr.append(output_txo_5_1.hh)
mmr.append(output_txo_5_2.hh)
mmr.append(output_txo_6_1.hh)
mmr.append(output_txo_6_2.hh)
root_3 = copy.deepcopy(mmr.root)
width_3 = copy.deepcopy(mmr.width)
peaks_3 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx5.json'), 'w+') as f:
    json.dump(tx_5.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx6.json'), 'w+') as f:
    json.dump(tx_6.to_dict(), f)

roll_up_proof_3 = PedersenMMR.zk_roll_up_proof(
    root_2,
    width_2,
    peaks_2,
    [output_txo_5_1.hh, output_txo_5_2.hh, output_txo_6_1.hh, output_txo_6_2.hh],
    root_3
)
with open(os.path.join(BUILD_PATH, 'rollUp3.json'), 'w+') as f:
    json.dump(roll_up_proof_3, f)

# Roll up round 4
input_txo_7_1 = output_txo_5_1
input_txo_7_2 = None

input_txo_7_1_inclusion_proof = mmr.get_inclusion_proof(9)
zk_inclusion_proof_input_txo_7_1 = input_txo_7_1_inclusion_proof.zk_proof(input_txo_7_1.r, input_txo_7_1.v)
zk_inclusion_proof_input_txo_7_2 = None

tx_7, output_txo_7_1, output_txo_7_2 = make_tx(
    input_txo_7_1, zk_inclusion_proof_input_txo_7_1,
    input_txo_7_2, zk_inclusion_proof_input_txo_7_2
)

mmr.append(output_txo_7_1.hh)
mmr.append(output_txo_7_2.hh)
root_4 = copy.deepcopy(mmr.root)
width_4 = copy.deepcopy(mmr.width)
peaks_4 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx7.json'), 'w+') as f:
    json.dump(tx_7.to_dict(), f)

roll_up_proof_4 = PedersenMMR.zk_roll_up_proof(
    root_3,
    width_3,
    peaks_3,
    [output_txo_7_1.hh, output_txo_7_2.hh],
    root_4
)

with open(os.path.join(BUILD_PATH, 'rollUp4.json'), 'w+') as f:
    json.dump(roll_up_proof_4, f)

# Roll up round 5
input_txo_8_1 = output_txo_6_1
input_txo_8_2 = output_txo_6_2

input_txo_8_1_inclusion_proof = mmr.get_inclusion_proof(11)
input_txo_8_2_inclusion_proof = mmr.get_inclusion_proof(12)
zk_inclusion_proof_input_txo_8_1 = input_txo_8_1_inclusion_proof.zk_proof(input_txo_8_1.r, input_txo_8_1.v)
zk_inclusion_proof_input_txo_8_2 = input_txo_8_2_inclusion_proof.zk_proof(input_txo_8_2.r, input_txo_8_2.v)

tx_8, output_txo_8_1, output_txo_8_2 = make_tx(
    input_txo_8_1, zk_inclusion_proof_input_txo_8_1,
    input_txo_8_2, zk_inclusion_proof_input_txo_8_2
)

mmr.append(output_txo_8_1.hh)
mmr.append(output_txo_8_2.hh)
root_5 = copy.deepcopy(mmr.root)
width_5 = copy.deepcopy(mmr.width)
peaks_5 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx8.json'), 'w+') as f:
    json.dump(tx_8.to_dict(), f)

roll_up_proof_5 = PedersenMMR.zk_roll_up_proof(
    root_4,
    width_4,
    peaks_4,
    [output_txo_8_1.hh, output_txo_8_2.hh],
    root_5
)

with open(os.path.join(BUILD_PATH, 'rollUp5.json'), 'w+') as f:
    json.dump(roll_up_proof_5, f)

# Withdraw
withdrawing_txo = output_txo_8_1
withdrawing_inclusion_proof = mmr.get_inclusion_proof(15)
r = withdrawing_txo.r
v = withdrawing_txo.v
zk_inclusion_proof = withdrawing_inclusion_proof.zk_proof(r, v)
zk_withdraw_proof = PedersenMMR.zk_withdraw_proof(root_5, 15, r, v, peaks_5, withdrawing_inclusion_proof.siblings)

with open(os.path.join(BUILD_PATH, 'inclusion.json'), 'w+') as f:
    json.dump(zk_inclusion_proof, f)

with open(os.path.join(BUILD_PATH, 'withdraw.json'), 'w+') as f:
    json.dump(zk_withdraw_proof, f)
