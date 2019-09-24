from ethsnarks.field import SNARK_SCALAR_FIELD

from py934.mimblewimble import TxSend, Output, Field, TxReceive, Transaction
from py934.mmr import PedersenMMR
import json
import copy
import os

BUILD_PATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'build')
ERC20_ADDRESS = int("0xACa6BFcc686ED93b5aa5820d5A7B7B82513c106c", 16)
EXPIRATION = 100


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
        metadata(ERC20_ADDRESS, EXPIRATION). \
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

# Optimistic roll up round 6 (4 transactions)
input_txo_9_1 = output_txo_7_1
input_txo_9_2 = None
input_txo_10_1 = output_txo_7_2
input_txo_10_2 = None
input_txo_11_1 = output_txo_8_1
input_txo_11_2 = None
input_txo_12_1 = output_txo_8_2
input_txo_12_2 = None

input_txo_9_1_inclusion_proof = mmr.get_inclusion_proof(13)
input_txo_10_1_inclusion_proof = mmr.get_inclusion_proof(14)
input_txo_11_1_inclusion_proof = mmr.get_inclusion_proof(15)
input_txo_12_1_inclusion_proof = mmr.get_inclusion_proof(16)

zk_inclusion_proof_input_txo_9_1 = input_txo_9_1_inclusion_proof.zk_proof(input_txo_9_1.r, input_txo_9_1.v)
zk_inclusion_proof_input_txo_10_1 = input_txo_10_1_inclusion_proof.zk_proof(input_txo_10_1.r, input_txo_10_1.v)
zk_inclusion_proof_input_txo_11_1 = input_txo_11_1_inclusion_proof.zk_proof(input_txo_11_1.r, input_txo_11_1.v)
zk_inclusion_proof_input_txo_12_1 = input_txo_12_1_inclusion_proof.zk_proof(input_txo_12_1.r, input_txo_12_1.v)

tx_9, output_txo_9_1, output_txo_9_2 = make_tx(input_txo_9_1, zk_inclusion_proof_input_txo_9_1, None, None)
tx_10, output_txo_10_1, output_txo_10_2 = make_tx(input_txo_10_1, zk_inclusion_proof_input_txo_10_1, None, None)
tx_11, output_txo_11_1, output_txo_11_2 = make_tx(input_txo_11_1, zk_inclusion_proof_input_txo_11_1, None, None)
tx_12, output_txo_12_1, output_txo_12_2 = make_tx(input_txo_12_1, zk_inclusion_proof_input_txo_12_1, None, None)

mmr.append(output_txo_9_1.hh)
mmr.append(output_txo_9_2.hh)
mmr.append(output_txo_10_1.hh)
mmr.append(output_txo_10_2.hh)
mmr.append(output_txo_11_1.hh)
mmr.append(output_txo_11_2.hh)
mmr.append(output_txo_12_1.hh)
mmr.append(output_txo_12_2.hh)

root_6 = copy.deepcopy(mmr.root)
width_6 = copy.deepcopy(mmr.width)
peaks_6 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx9.json'), 'w+') as f:
    json.dump(tx_9.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx10.json'), 'w+') as f:
    json.dump(tx_10.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx11.json'), 'w+') as f:
    json.dump(tx_11.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx12.json'), 'w+') as f:
    json.dump(tx_12.to_dict(), f)

roll_up_proof_6 = PedersenMMR.zk_roll_up_proof(
    root_5,
    width_5,
    peaks_5,
    [
        output_txo_9_1.hh, output_txo_9_2.hh,
        output_txo_10_1.hh, output_txo_10_2.hh,
        output_txo_11_1.hh, output_txo_11_2.hh,
        output_txo_12_1.hh, output_txo_12_2.hh
    ],
    root_6
)

with open(os.path.join(BUILD_PATH, 'rollUp6.json'), 'w+') as f:
    json.dump(roll_up_proof_6, f)

# Optimistic roll up round 7 (8 transactions)
input_txo_13_1 = output_txo_9_1
input_txo_14_1 = output_txo_9_2
input_txo_15_1 = output_txo_10_1
input_txo_16_1 = output_txo_10_2
input_txo_17_1 = output_txo_11_1
input_txo_18_1 = output_txo_11_2
input_txo_19_1 = output_txo_12_1
input_txo_20_1 = output_txo_12_2

input_txo_13_1_inclusion_proof = mmr.get_inclusion_proof(17)
input_txo_14_1_inclusion_proof = mmr.get_inclusion_proof(18)
input_txo_15_1_inclusion_proof = mmr.get_inclusion_proof(19)
input_txo_16_1_inclusion_proof = mmr.get_inclusion_proof(20)
input_txo_17_1_inclusion_proof = mmr.get_inclusion_proof(21)
input_txo_18_1_inclusion_proof = mmr.get_inclusion_proof(22)
input_txo_19_1_inclusion_proof = mmr.get_inclusion_proof(23)
input_txo_20_1_inclusion_proof = mmr.get_inclusion_proof(24)

zk_inclusion_proof_input_txo_13_1 = input_txo_13_1_inclusion_proof.zk_proof(input_txo_13_1.r, input_txo_13_1.v)
zk_inclusion_proof_input_txo_14_1 = input_txo_14_1_inclusion_proof.zk_proof(input_txo_14_1.r, input_txo_14_1.v)
zk_inclusion_proof_input_txo_15_1 = input_txo_15_1_inclusion_proof.zk_proof(input_txo_15_1.r, input_txo_15_1.v)
zk_inclusion_proof_input_txo_16_1 = input_txo_16_1_inclusion_proof.zk_proof(input_txo_16_1.r, input_txo_16_1.v)
zk_inclusion_proof_input_txo_17_1 = input_txo_17_1_inclusion_proof.zk_proof(input_txo_17_1.r, input_txo_17_1.v)
zk_inclusion_proof_input_txo_18_1 = input_txo_18_1_inclusion_proof.zk_proof(input_txo_18_1.r, input_txo_18_1.v)
zk_inclusion_proof_input_txo_19_1 = input_txo_19_1_inclusion_proof.zk_proof(input_txo_19_1.r, input_txo_19_1.v)
zk_inclusion_proof_input_txo_20_1 = input_txo_20_1_inclusion_proof.zk_proof(input_txo_20_1.r, input_txo_20_1.v)

tx_13, output_txo_13_1, output_txo_13_2 = make_tx(input_txo_13_1, zk_inclusion_proof_input_txo_13_1, None, None)
tx_14, output_txo_14_1, output_txo_14_2 = make_tx(input_txo_14_1, zk_inclusion_proof_input_txo_14_1, None, None)
tx_15, output_txo_15_1, output_txo_15_2 = make_tx(input_txo_15_1, zk_inclusion_proof_input_txo_15_1, None, None)
tx_16, output_txo_16_1, output_txo_16_2 = make_tx(input_txo_16_1, zk_inclusion_proof_input_txo_16_1, None, None)
tx_17, output_txo_17_1, output_txo_17_2 = make_tx(input_txo_17_1, zk_inclusion_proof_input_txo_17_1, None, None)
tx_18, output_txo_18_1, output_txo_18_2 = make_tx(input_txo_18_1, zk_inclusion_proof_input_txo_18_1, None, None)
tx_19, output_txo_19_1, output_txo_19_2 = make_tx(input_txo_19_1, zk_inclusion_proof_input_txo_19_1, None, None)
tx_20, output_txo_20_1, output_txo_20_2 = make_tx(input_txo_20_1, zk_inclusion_proof_input_txo_20_1, None, None)

mmr.append(output_txo_13_1.hh)
mmr.append(output_txo_13_2.hh)
mmr.append(output_txo_14_1.hh)
mmr.append(output_txo_14_2.hh)
mmr.append(output_txo_15_1.hh)
mmr.append(output_txo_15_2.hh)
mmr.append(output_txo_16_1.hh)
mmr.append(output_txo_16_2.hh)
mmr.append(output_txo_17_1.hh)
mmr.append(output_txo_17_2.hh)
mmr.append(output_txo_18_1.hh)
mmr.append(output_txo_18_2.hh)
mmr.append(output_txo_19_1.hh)
mmr.append(output_txo_19_2.hh)
mmr.append(output_txo_20_1.hh)
mmr.append(output_txo_20_2.hh)

root_7 = copy.deepcopy(mmr.root)
width_7 = copy.deepcopy(mmr.width)
peaks_7 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx13.json'), 'w+') as f:
    json.dump(tx_13.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx14.json'), 'w+') as f:
    json.dump(tx_14.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx15.json'), 'w+') as f:
    json.dump(tx_15.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx16.json'), 'w+') as f:
    json.dump(tx_16.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx17.json'), 'w+') as f:
    json.dump(tx_17.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx18.json'), 'w+') as f:
    json.dump(tx_18.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx19.json'), 'w+') as f:
    json.dump(tx_19.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx20.json'), 'w+') as f:
    json.dump(tx_20.to_dict(), f)

roll_up_proof_7 = PedersenMMR.zk_roll_up_proof(
    root_6,
    width_6,
    peaks_6,
    [
        output_txo_13_1.hh, output_txo_13_2.hh,
        output_txo_14_1.hh, output_txo_14_2.hh,
        output_txo_15_1.hh, output_txo_15_2.hh,
        output_txo_16_1.hh, output_txo_16_2.hh,
        output_txo_17_1.hh, output_txo_17_2.hh,
        output_txo_18_1.hh, output_txo_18_2.hh,
        output_txo_19_1.hh, output_txo_19_2.hh,
        output_txo_20_1.hh, output_txo_20_2.hh
    ],
    root_7
)

with open(os.path.join(BUILD_PATH, 'rollUp7.json'), 'w+') as f:
    json.dump(roll_up_proof_7, f)

# Optimistic roll up round 8 (16 transactions)
input_txo_21_1 = output_txo_13_1
input_txo_22_1 = output_txo_13_2
input_txo_23_1 = output_txo_14_1
input_txo_24_1 = output_txo_14_2
input_txo_25_1 = output_txo_15_1
input_txo_26_1 = output_txo_15_2
input_txo_27_1 = output_txo_16_1
input_txo_28_1 = output_txo_16_2
input_txo_29_1 = output_txo_17_1
input_txo_30_1 = output_txo_17_2
input_txo_31_1 = output_txo_18_1
input_txo_32_1 = output_txo_18_2
input_txo_33_1 = output_txo_19_1
input_txo_34_1 = output_txo_19_2
input_txo_35_1 = output_txo_20_1
input_txo_36_1 = output_txo_20_2

input_txo_21_1_inclusion_proof = mmr.get_inclusion_proof(25)
input_txo_22_1_inclusion_proof = mmr.get_inclusion_proof(26)
input_txo_23_1_inclusion_proof = mmr.get_inclusion_proof(27)
input_txo_24_1_inclusion_proof = mmr.get_inclusion_proof(28)
input_txo_25_1_inclusion_proof = mmr.get_inclusion_proof(29)
input_txo_26_1_inclusion_proof = mmr.get_inclusion_proof(30)
input_txo_27_1_inclusion_proof = mmr.get_inclusion_proof(31)
input_txo_28_1_inclusion_proof = mmr.get_inclusion_proof(32)
input_txo_29_1_inclusion_proof = mmr.get_inclusion_proof(33)
input_txo_30_1_inclusion_proof = mmr.get_inclusion_proof(34)
input_txo_31_1_inclusion_proof = mmr.get_inclusion_proof(35)
input_txo_32_1_inclusion_proof = mmr.get_inclusion_proof(36)
input_txo_33_1_inclusion_proof = mmr.get_inclusion_proof(37)
input_txo_34_1_inclusion_proof = mmr.get_inclusion_proof(38)
input_txo_35_1_inclusion_proof = mmr.get_inclusion_proof(39)
input_txo_36_1_inclusion_proof = mmr.get_inclusion_proof(40)

zk_inclusion_proof_input_txo_21_1 = input_txo_21_1_inclusion_proof.zk_proof(input_txo_21_1.r, input_txo_21_1.v)
zk_inclusion_proof_input_txo_22_1 = input_txo_22_1_inclusion_proof.zk_proof(input_txo_22_1.r, input_txo_22_1.v)
zk_inclusion_proof_input_txo_23_1 = input_txo_23_1_inclusion_proof.zk_proof(input_txo_23_1.r, input_txo_23_1.v)
zk_inclusion_proof_input_txo_24_1 = input_txo_24_1_inclusion_proof.zk_proof(input_txo_24_1.r, input_txo_24_1.v)
zk_inclusion_proof_input_txo_25_1 = input_txo_25_1_inclusion_proof.zk_proof(input_txo_25_1.r, input_txo_25_1.v)
zk_inclusion_proof_input_txo_26_1 = input_txo_26_1_inclusion_proof.zk_proof(input_txo_26_1.r, input_txo_26_1.v)
zk_inclusion_proof_input_txo_27_1 = input_txo_27_1_inclusion_proof.zk_proof(input_txo_27_1.r, input_txo_27_1.v)
zk_inclusion_proof_input_txo_28_1 = input_txo_28_1_inclusion_proof.zk_proof(input_txo_28_1.r, input_txo_28_1.v)
zk_inclusion_proof_input_txo_29_1 = input_txo_29_1_inclusion_proof.zk_proof(input_txo_29_1.r, input_txo_29_1.v)
zk_inclusion_proof_input_txo_30_1 = input_txo_30_1_inclusion_proof.zk_proof(input_txo_30_1.r, input_txo_30_1.v)
zk_inclusion_proof_input_txo_31_1 = input_txo_31_1_inclusion_proof.zk_proof(input_txo_31_1.r, input_txo_31_1.v)
zk_inclusion_proof_input_txo_32_1 = input_txo_32_1_inclusion_proof.zk_proof(input_txo_32_1.r, input_txo_32_1.v)
zk_inclusion_proof_input_txo_33_1 = input_txo_33_1_inclusion_proof.zk_proof(input_txo_33_1.r, input_txo_33_1.v)
zk_inclusion_proof_input_txo_34_1 = input_txo_34_1_inclusion_proof.zk_proof(input_txo_34_1.r, input_txo_34_1.v)
zk_inclusion_proof_input_txo_35_1 = input_txo_35_1_inclusion_proof.zk_proof(input_txo_35_1.r, input_txo_35_1.v)
zk_inclusion_proof_input_txo_36_1 = input_txo_36_1_inclusion_proof.zk_proof(input_txo_36_1.r, input_txo_36_1.v)

tx_21, output_txo_21_1, output_txo_21_2 = make_tx(input_txo_21_1, zk_inclusion_proof_input_txo_21_1, None, None)
tx_22, output_txo_22_1, output_txo_22_2 = make_tx(input_txo_22_1, zk_inclusion_proof_input_txo_22_1, None, None)
tx_23, output_txo_23_1, output_txo_23_2 = make_tx(input_txo_23_1, zk_inclusion_proof_input_txo_23_1, None, None)
tx_24, output_txo_24_1, output_txo_24_2 = make_tx(input_txo_24_1, zk_inclusion_proof_input_txo_24_1, None, None)
tx_25, output_txo_25_1, output_txo_25_2 = make_tx(input_txo_25_1, zk_inclusion_proof_input_txo_25_1, None, None)
tx_26, output_txo_26_1, output_txo_26_2 = make_tx(input_txo_26_1, zk_inclusion_proof_input_txo_26_1, None, None)
tx_27, output_txo_27_1, output_txo_27_2 = make_tx(input_txo_27_1, zk_inclusion_proof_input_txo_27_1, None, None)
tx_28, output_txo_28_1, output_txo_28_2 = make_tx(input_txo_28_1, zk_inclusion_proof_input_txo_28_1, None, None)
tx_29, output_txo_29_1, output_txo_29_2 = make_tx(input_txo_29_1, zk_inclusion_proof_input_txo_29_1, None, None)
tx_30, output_txo_30_1, output_txo_30_2 = make_tx(input_txo_30_1, zk_inclusion_proof_input_txo_30_1, None, None)
tx_31, output_txo_31_1, output_txo_31_2 = make_tx(input_txo_31_1, zk_inclusion_proof_input_txo_31_1, None, None)
tx_32, output_txo_32_1, output_txo_32_2 = make_tx(input_txo_32_1, zk_inclusion_proof_input_txo_32_1, None, None)
tx_33, output_txo_33_1, output_txo_33_2 = make_tx(input_txo_33_1, zk_inclusion_proof_input_txo_33_1, None, None)
tx_34, output_txo_34_1, output_txo_34_2 = make_tx(input_txo_34_1, zk_inclusion_proof_input_txo_34_1, None, None)
tx_35, output_txo_35_1, output_txo_35_2 = make_tx(input_txo_35_1, zk_inclusion_proof_input_txo_35_1, None, None)
tx_36, output_txo_36_1, output_txo_36_2 = make_tx(input_txo_36_1, zk_inclusion_proof_input_txo_36_1, None, None)

mmr.append(output_txo_21_1.hh)
mmr.append(output_txo_21_2.hh)
mmr.append(output_txo_22_1.hh)
mmr.append(output_txo_22_2.hh)
mmr.append(output_txo_23_1.hh)
mmr.append(output_txo_23_2.hh)
mmr.append(output_txo_24_1.hh)
mmr.append(output_txo_24_2.hh)
mmr.append(output_txo_25_1.hh)
mmr.append(output_txo_25_2.hh)
mmr.append(output_txo_26_1.hh)
mmr.append(output_txo_26_2.hh)
mmr.append(output_txo_27_1.hh)
mmr.append(output_txo_27_2.hh)
mmr.append(output_txo_28_1.hh)
mmr.append(output_txo_28_2.hh)
mmr.append(output_txo_29_1.hh)
mmr.append(output_txo_29_2.hh)
mmr.append(output_txo_30_1.hh)
mmr.append(output_txo_30_2.hh)
mmr.append(output_txo_31_1.hh)
mmr.append(output_txo_31_2.hh)
mmr.append(output_txo_32_1.hh)
mmr.append(output_txo_32_2.hh)
mmr.append(output_txo_33_1.hh)
mmr.append(output_txo_33_2.hh)
mmr.append(output_txo_34_1.hh)
mmr.append(output_txo_34_2.hh)
mmr.append(output_txo_35_1.hh)
mmr.append(output_txo_35_2.hh)
mmr.append(output_txo_36_1.hh)
mmr.append(output_txo_36_2.hh)

root_8 = copy.deepcopy(mmr.root)
width_8 = copy.deepcopy(mmr.width)
peaks_8 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx21.json'), 'w+') as f:
    json.dump(tx_21.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx22.json'), 'w+') as f:
    json.dump(tx_22.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx23.json'), 'w+') as f:
    json.dump(tx_23.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx24.json'), 'w+') as f:
    json.dump(tx_24.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx25.json'), 'w+') as f:
    json.dump(tx_25.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx26.json'), 'w+') as f:
    json.dump(tx_26.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx27.json'), 'w+') as f:
    json.dump(tx_27.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx28.json'), 'w+') as f:
    json.dump(tx_28.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx29.json'), 'w+') as f:
    json.dump(tx_29.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx30.json'), 'w+') as f:
    json.dump(tx_30.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx31.json'), 'w+') as f:
    json.dump(tx_31.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx32.json'), 'w+') as f:
    json.dump(tx_32.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx33.json'), 'w+') as f:
    json.dump(tx_33.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx34.json'), 'w+') as f:
    json.dump(tx_34.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx35.json'), 'w+') as f:
    json.dump(tx_35.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx36.json'), 'w+') as f:
    json.dump(tx_36.to_dict(), f)

roll_up_proof_8 = PedersenMMR.zk_roll_up_proof(
    root_7,
    width_7,
    peaks_7,
    [
        output_txo_21_1.hh, output_txo_21_2.hh,
        output_txo_22_1.hh, output_txo_22_2.hh,
        output_txo_23_1.hh, output_txo_23_2.hh,
        output_txo_24_1.hh, output_txo_24_2.hh,
        output_txo_25_1.hh, output_txo_25_2.hh,
        output_txo_26_1.hh, output_txo_26_2.hh,
        output_txo_27_1.hh, output_txo_27_2.hh,
        output_txo_28_1.hh, output_txo_28_2.hh,
        output_txo_29_1.hh, output_txo_29_2.hh,
        output_txo_30_1.hh, output_txo_30_2.hh,
        output_txo_31_1.hh, output_txo_31_2.hh,
        output_txo_32_1.hh, output_txo_32_2.hh,
        output_txo_33_1.hh, output_txo_33_2.hh,
        output_txo_34_1.hh, output_txo_34_2.hh,
        output_txo_35_1.hh, output_txo_35_2.hh,
        output_txo_36_1.hh, output_txo_36_2.hh,
    ],
    root_8
)

with open(os.path.join(BUILD_PATH, 'rollUp8.json'), 'w+') as f:
    json.dump(roll_up_proof_8, f)


# Optimistic roll up round 9 (32 transactions)
input_txo_37_1 = output_txo_21_1
input_txo_38_1 = output_txo_21_2
input_txo_39_1 = output_txo_22_1
input_txo_40_1 = output_txo_22_2
input_txo_41_1 = output_txo_23_1
input_txo_42_1 = output_txo_23_2
input_txo_43_1 = output_txo_24_1
input_txo_44_1 = output_txo_24_2
input_txo_45_1 = output_txo_25_1
input_txo_46_1 = output_txo_25_2
input_txo_47_1 = output_txo_26_1
input_txo_48_1 = output_txo_26_2
input_txo_49_1 = output_txo_27_1
input_txo_50_1 = output_txo_27_2
input_txo_51_1 = output_txo_28_1
input_txo_52_1 = output_txo_28_2
input_txo_53_1 = output_txo_29_1
input_txo_54_1 = output_txo_29_2
input_txo_55_1 = output_txo_30_1
input_txo_56_1 = output_txo_30_2
input_txo_57_1 = output_txo_31_1
input_txo_58_1 = output_txo_31_2
input_txo_59_1 = output_txo_32_1
input_txo_60_1 = output_txo_32_2
input_txo_61_1 = output_txo_33_1
input_txo_62_1 = output_txo_33_2
input_txo_63_1 = output_txo_34_1
input_txo_64_1 = output_txo_34_2
input_txo_65_1 = output_txo_35_1
input_txo_66_1 = output_txo_35_2
input_txo_67_1 = output_txo_36_1
input_txo_68_1 = output_txo_36_2

input_txo_37_1_inclusion_proof = mmr.get_inclusion_proof(41)
input_txo_38_1_inclusion_proof = mmr.get_inclusion_proof(42)
input_txo_39_1_inclusion_proof = mmr.get_inclusion_proof(43)
input_txo_40_1_inclusion_proof = mmr.get_inclusion_proof(44)
input_txo_41_1_inclusion_proof = mmr.get_inclusion_proof(45)
input_txo_42_1_inclusion_proof = mmr.get_inclusion_proof(46)
input_txo_43_1_inclusion_proof = mmr.get_inclusion_proof(47)
input_txo_44_1_inclusion_proof = mmr.get_inclusion_proof(48)
input_txo_45_1_inclusion_proof = mmr.get_inclusion_proof(49)
input_txo_46_1_inclusion_proof = mmr.get_inclusion_proof(50)
input_txo_47_1_inclusion_proof = mmr.get_inclusion_proof(51)
input_txo_48_1_inclusion_proof = mmr.get_inclusion_proof(52)
input_txo_49_1_inclusion_proof = mmr.get_inclusion_proof(53)
input_txo_50_1_inclusion_proof = mmr.get_inclusion_proof(54)
input_txo_51_1_inclusion_proof = mmr.get_inclusion_proof(55)
input_txo_52_1_inclusion_proof = mmr.get_inclusion_proof(56)
input_txo_53_1_inclusion_proof = mmr.get_inclusion_proof(57)
input_txo_54_1_inclusion_proof = mmr.get_inclusion_proof(58)
input_txo_55_1_inclusion_proof = mmr.get_inclusion_proof(59)
input_txo_56_1_inclusion_proof = mmr.get_inclusion_proof(60)
input_txo_57_1_inclusion_proof = mmr.get_inclusion_proof(61)
input_txo_58_1_inclusion_proof = mmr.get_inclusion_proof(62)
input_txo_59_1_inclusion_proof = mmr.get_inclusion_proof(63)
input_txo_60_1_inclusion_proof = mmr.get_inclusion_proof(64)
input_txo_61_1_inclusion_proof = mmr.get_inclusion_proof(65)
input_txo_62_1_inclusion_proof = mmr.get_inclusion_proof(66)
input_txo_63_1_inclusion_proof = mmr.get_inclusion_proof(67)
input_txo_64_1_inclusion_proof = mmr.get_inclusion_proof(68)
input_txo_65_1_inclusion_proof = mmr.get_inclusion_proof(69)
input_txo_66_1_inclusion_proof = mmr.get_inclusion_proof(70)
input_txo_67_1_inclusion_proof = mmr.get_inclusion_proof(71)
input_txo_68_1_inclusion_proof = mmr.get_inclusion_proof(72)

zk_inclusion_proof_input_txo_37_1 = input_txo_37_1_inclusion_proof.zk_proof(input_txo_37_1.r, input_txo_37_1.v)
zk_inclusion_proof_input_txo_38_1 = input_txo_38_1_inclusion_proof.zk_proof(input_txo_38_1.r, input_txo_38_1.v)
zk_inclusion_proof_input_txo_39_1 = input_txo_39_1_inclusion_proof.zk_proof(input_txo_39_1.r, input_txo_39_1.v)
zk_inclusion_proof_input_txo_40_1 = input_txo_40_1_inclusion_proof.zk_proof(input_txo_40_1.r, input_txo_40_1.v)
zk_inclusion_proof_input_txo_41_1 = input_txo_41_1_inclusion_proof.zk_proof(input_txo_41_1.r, input_txo_41_1.v)
zk_inclusion_proof_input_txo_42_1 = input_txo_42_1_inclusion_proof.zk_proof(input_txo_42_1.r, input_txo_42_1.v)
zk_inclusion_proof_input_txo_43_1 = input_txo_43_1_inclusion_proof.zk_proof(input_txo_43_1.r, input_txo_43_1.v)
zk_inclusion_proof_input_txo_44_1 = input_txo_44_1_inclusion_proof.zk_proof(input_txo_44_1.r, input_txo_44_1.v)
zk_inclusion_proof_input_txo_45_1 = input_txo_45_1_inclusion_proof.zk_proof(input_txo_45_1.r, input_txo_45_1.v)
zk_inclusion_proof_input_txo_46_1 = input_txo_46_1_inclusion_proof.zk_proof(input_txo_46_1.r, input_txo_46_1.v)
zk_inclusion_proof_input_txo_47_1 = input_txo_47_1_inclusion_proof.zk_proof(input_txo_47_1.r, input_txo_47_1.v)
zk_inclusion_proof_input_txo_48_1 = input_txo_48_1_inclusion_proof.zk_proof(input_txo_48_1.r, input_txo_48_1.v)
zk_inclusion_proof_input_txo_49_1 = input_txo_49_1_inclusion_proof.zk_proof(input_txo_49_1.r, input_txo_49_1.v)
zk_inclusion_proof_input_txo_50_1 = input_txo_50_1_inclusion_proof.zk_proof(input_txo_50_1.r, input_txo_50_1.v)
zk_inclusion_proof_input_txo_51_1 = input_txo_51_1_inclusion_proof.zk_proof(input_txo_51_1.r, input_txo_51_1.v)
zk_inclusion_proof_input_txo_52_1 = input_txo_52_1_inclusion_proof.zk_proof(input_txo_52_1.r, input_txo_52_1.v)
zk_inclusion_proof_input_txo_53_1 = input_txo_53_1_inclusion_proof.zk_proof(input_txo_53_1.r, input_txo_53_1.v)
zk_inclusion_proof_input_txo_54_1 = input_txo_54_1_inclusion_proof.zk_proof(input_txo_54_1.r, input_txo_54_1.v)
zk_inclusion_proof_input_txo_55_1 = input_txo_55_1_inclusion_proof.zk_proof(input_txo_55_1.r, input_txo_55_1.v)
zk_inclusion_proof_input_txo_56_1 = input_txo_56_1_inclusion_proof.zk_proof(input_txo_56_1.r, input_txo_56_1.v)
zk_inclusion_proof_input_txo_57_1 = input_txo_57_1_inclusion_proof.zk_proof(input_txo_57_1.r, input_txo_57_1.v)
zk_inclusion_proof_input_txo_58_1 = input_txo_58_1_inclusion_proof.zk_proof(input_txo_58_1.r, input_txo_58_1.v)
zk_inclusion_proof_input_txo_59_1 = input_txo_59_1_inclusion_proof.zk_proof(input_txo_59_1.r, input_txo_59_1.v)
zk_inclusion_proof_input_txo_60_1 = input_txo_60_1_inclusion_proof.zk_proof(input_txo_60_1.r, input_txo_60_1.v)
zk_inclusion_proof_input_txo_61_1 = input_txo_61_1_inclusion_proof.zk_proof(input_txo_61_1.r, input_txo_61_1.v)
zk_inclusion_proof_input_txo_62_1 = input_txo_62_1_inclusion_proof.zk_proof(input_txo_62_1.r, input_txo_62_1.v)
zk_inclusion_proof_input_txo_63_1 = input_txo_63_1_inclusion_proof.zk_proof(input_txo_63_1.r, input_txo_63_1.v)
zk_inclusion_proof_input_txo_64_1 = input_txo_64_1_inclusion_proof.zk_proof(input_txo_64_1.r, input_txo_64_1.v)
zk_inclusion_proof_input_txo_65_1 = input_txo_65_1_inclusion_proof.zk_proof(input_txo_65_1.r, input_txo_65_1.v)
zk_inclusion_proof_input_txo_66_1 = input_txo_66_1_inclusion_proof.zk_proof(input_txo_66_1.r, input_txo_66_1.v)
zk_inclusion_proof_input_txo_67_1 = input_txo_67_1_inclusion_proof.zk_proof(input_txo_67_1.r, input_txo_67_1.v)
zk_inclusion_proof_input_txo_68_1 = input_txo_68_1_inclusion_proof.zk_proof(input_txo_68_1.r, input_txo_68_1.v)

tx_37, output_txo_37_1, output_txo_37_2 = make_tx(input_txo_37_1, zk_inclusion_proof_input_txo_37_1, None, None)
tx_38, output_txo_38_1, output_txo_38_2 = make_tx(input_txo_38_1, zk_inclusion_proof_input_txo_38_1, None, None)
tx_39, output_txo_39_1, output_txo_39_2 = make_tx(input_txo_39_1, zk_inclusion_proof_input_txo_39_1, None, None)
tx_40, output_txo_40_1, output_txo_40_2 = make_tx(input_txo_40_1, zk_inclusion_proof_input_txo_40_1, None, None)
tx_41, output_txo_41_1, output_txo_41_2 = make_tx(input_txo_41_1, zk_inclusion_proof_input_txo_41_1, None, None)
tx_42, output_txo_42_1, output_txo_42_2 = make_tx(input_txo_42_1, zk_inclusion_proof_input_txo_42_1, None, None)
tx_43, output_txo_43_1, output_txo_43_2 = make_tx(input_txo_43_1, zk_inclusion_proof_input_txo_43_1, None, None)
tx_44, output_txo_44_1, output_txo_44_2 = make_tx(input_txo_44_1, zk_inclusion_proof_input_txo_44_1, None, None)
tx_45, output_txo_45_1, output_txo_45_2 = make_tx(input_txo_45_1, zk_inclusion_proof_input_txo_45_1, None, None)
tx_46, output_txo_46_1, output_txo_46_2 = make_tx(input_txo_46_1, zk_inclusion_proof_input_txo_46_1, None, None)
tx_47, output_txo_47_1, output_txo_47_2 = make_tx(input_txo_47_1, zk_inclusion_proof_input_txo_47_1, None, None)
tx_48, output_txo_48_1, output_txo_48_2 = make_tx(input_txo_48_1, zk_inclusion_proof_input_txo_48_1, None, None)
tx_49, output_txo_49_1, output_txo_49_2 = make_tx(input_txo_49_1, zk_inclusion_proof_input_txo_49_1, None, None)
tx_50, output_txo_50_1, output_txo_50_2 = make_tx(input_txo_50_1, zk_inclusion_proof_input_txo_50_1, None, None)
tx_51, output_txo_51_1, output_txo_51_2 = make_tx(input_txo_51_1, zk_inclusion_proof_input_txo_51_1, None, None)
tx_52, output_txo_52_1, output_txo_52_2 = make_tx(input_txo_52_1, zk_inclusion_proof_input_txo_52_1, None, None)
tx_53, output_txo_53_1, output_txo_53_2 = make_tx(input_txo_53_1, zk_inclusion_proof_input_txo_53_1, None, None)
tx_54, output_txo_54_1, output_txo_54_2 = make_tx(input_txo_54_1, zk_inclusion_proof_input_txo_54_1, None, None)
tx_55, output_txo_55_1, output_txo_55_2 = make_tx(input_txo_55_1, zk_inclusion_proof_input_txo_55_1, None, None)
tx_56, output_txo_56_1, output_txo_56_2 = make_tx(input_txo_56_1, zk_inclusion_proof_input_txo_56_1, None, None)
tx_57, output_txo_57_1, output_txo_57_2 = make_tx(input_txo_57_1, zk_inclusion_proof_input_txo_57_1, None, None)
tx_58, output_txo_58_1, output_txo_58_2 = make_tx(input_txo_58_1, zk_inclusion_proof_input_txo_58_1, None, None)
tx_59, output_txo_59_1, output_txo_59_2 = make_tx(input_txo_59_1, zk_inclusion_proof_input_txo_59_1, None, None)
tx_60, output_txo_60_1, output_txo_60_2 = make_tx(input_txo_60_1, zk_inclusion_proof_input_txo_60_1, None, None)
tx_61, output_txo_61_1, output_txo_61_2 = make_tx(input_txo_61_1, zk_inclusion_proof_input_txo_61_1, None, None)
tx_62, output_txo_62_1, output_txo_62_2 = make_tx(input_txo_62_1, zk_inclusion_proof_input_txo_62_1, None, None)
tx_63, output_txo_63_1, output_txo_63_2 = make_tx(input_txo_63_1, zk_inclusion_proof_input_txo_63_1, None, None)
tx_64, output_txo_64_1, output_txo_64_2 = make_tx(input_txo_64_1, zk_inclusion_proof_input_txo_64_1, None, None)
tx_65, output_txo_65_1, output_txo_65_2 = make_tx(input_txo_65_1, zk_inclusion_proof_input_txo_65_1, None, None)
tx_66, output_txo_66_1, output_txo_66_2 = make_tx(input_txo_66_1, zk_inclusion_proof_input_txo_66_1, None, None)
tx_67, output_txo_67_1, output_txo_67_2 = make_tx(input_txo_67_1, zk_inclusion_proof_input_txo_67_1, None, None)
tx_68, output_txo_68_1, output_txo_68_2 = make_tx(input_txo_68_1, zk_inclusion_proof_input_txo_68_1, None, None)

mmr.append(output_txo_37_1.hh)
mmr.append(output_txo_37_2.hh)
mmr.append(output_txo_38_1.hh)
mmr.append(output_txo_38_2.hh)
mmr.append(output_txo_39_1.hh)
mmr.append(output_txo_39_2.hh)
mmr.append(output_txo_40_1.hh)
mmr.append(output_txo_40_2.hh)
mmr.append(output_txo_41_1.hh)
mmr.append(output_txo_41_2.hh)
mmr.append(output_txo_42_1.hh)
mmr.append(output_txo_42_2.hh)
mmr.append(output_txo_43_1.hh)
mmr.append(output_txo_43_2.hh)
mmr.append(output_txo_44_1.hh)
mmr.append(output_txo_44_2.hh)
mmr.append(output_txo_45_1.hh)
mmr.append(output_txo_45_2.hh)
mmr.append(output_txo_46_1.hh)
mmr.append(output_txo_46_2.hh)
mmr.append(output_txo_47_1.hh)
mmr.append(output_txo_47_2.hh)
mmr.append(output_txo_48_1.hh)
mmr.append(output_txo_48_2.hh)
mmr.append(output_txo_49_1.hh)
mmr.append(output_txo_49_2.hh)
mmr.append(output_txo_50_1.hh)
mmr.append(output_txo_50_2.hh)
mmr.append(output_txo_51_1.hh)
mmr.append(output_txo_51_2.hh)
mmr.append(output_txo_52_1.hh)
mmr.append(output_txo_52_2.hh)
mmr.append(output_txo_53_1.hh)
mmr.append(output_txo_53_2.hh)
mmr.append(output_txo_54_1.hh)
mmr.append(output_txo_54_2.hh)
mmr.append(output_txo_55_1.hh)
mmr.append(output_txo_55_2.hh)
mmr.append(output_txo_56_1.hh)
mmr.append(output_txo_56_2.hh)
mmr.append(output_txo_57_1.hh)
mmr.append(output_txo_57_2.hh)
mmr.append(output_txo_58_1.hh)
mmr.append(output_txo_58_2.hh)
mmr.append(output_txo_59_1.hh)
mmr.append(output_txo_59_2.hh)
mmr.append(output_txo_60_1.hh)
mmr.append(output_txo_60_2.hh)
mmr.append(output_txo_61_1.hh)
mmr.append(output_txo_61_2.hh)
mmr.append(output_txo_62_1.hh)
mmr.append(output_txo_62_2.hh)
mmr.append(output_txo_63_1.hh)
mmr.append(output_txo_63_2.hh)
mmr.append(output_txo_64_1.hh)
mmr.append(output_txo_64_2.hh)
mmr.append(output_txo_65_1.hh)
mmr.append(output_txo_65_2.hh)
mmr.append(output_txo_66_1.hh)
mmr.append(output_txo_66_2.hh)
mmr.append(output_txo_67_1.hh)
mmr.append(output_txo_67_2.hh)
mmr.append(output_txo_68_1.hh)
mmr.append(output_txo_68_2.hh)

root_9 = copy.deepcopy(mmr.root)
width_9 = copy.deepcopy(mmr.width)
peaks_9 = copy.deepcopy(mmr.peaks)

with open(os.path.join(BUILD_PATH, 'tx37.json'), 'w+') as f:
    json.dump(tx_37.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx38.json'), 'w+') as f:
    json.dump(tx_38.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx39.json'), 'w+') as f:
    json.dump(tx_39.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx40.json'), 'w+') as f:
    json.dump(tx_40.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx41.json'), 'w+') as f:
    json.dump(tx_41.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx42.json'), 'w+') as f:
    json.dump(tx_42.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx43.json'), 'w+') as f:
    json.dump(tx_43.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx44.json'), 'w+') as f:
    json.dump(tx_44.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx45.json'), 'w+') as f:
    json.dump(tx_45.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx46.json'), 'w+') as f:
    json.dump(tx_46.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx47.json'), 'w+') as f:
    json.dump(tx_47.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx48.json'), 'w+') as f:
    json.dump(tx_48.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx49.json'), 'w+') as f:
    json.dump(tx_49.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx50.json'), 'w+') as f:
    json.dump(tx_50.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx51.json'), 'w+') as f:
    json.dump(tx_51.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx52.json'), 'w+') as f:
    json.dump(tx_52.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx53.json'), 'w+') as f:
    json.dump(tx_53.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx54.json'), 'w+') as f:
    json.dump(tx_54.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx55.json'), 'w+') as f:
    json.dump(tx_55.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx56.json'), 'w+') as f:
    json.dump(tx_56.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx57.json'), 'w+') as f:
    json.dump(tx_57.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx58.json'), 'w+') as f:
    json.dump(tx_58.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx59.json'), 'w+') as f:
    json.dump(tx_59.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx60.json'), 'w+') as f:
    json.dump(tx_60.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx61.json'), 'w+') as f:
    json.dump(tx_61.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx62.json'), 'w+') as f:
    json.dump(tx_62.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx63.json'), 'w+') as f:
    json.dump(tx_63.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx64.json'), 'w+') as f:
    json.dump(tx_64.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx65.json'), 'w+') as f:
    json.dump(tx_65.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx66.json'), 'w+') as f:
    json.dump(tx_66.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx67.json'), 'w+') as f:
    json.dump(tx_67.to_dict(), f)
with open(os.path.join(BUILD_PATH, 'tx68.json'), 'w+') as f:
    json.dump(tx_68.to_dict(), f)

roll_up_proof_9 = PedersenMMR.zk_roll_up_proof(
    root_8,
    width_8,
    peaks_8,
    [
        output_txo_37_1.hh, output_txo_37_2.hh,
        output_txo_38_1.hh, output_txo_38_2.hh,
        output_txo_39_1.hh, output_txo_39_2.hh,
        output_txo_40_1.hh, output_txo_40_2.hh,
        output_txo_41_1.hh, output_txo_41_2.hh,
        output_txo_42_1.hh, output_txo_42_2.hh,
        output_txo_43_1.hh, output_txo_43_2.hh,
        output_txo_44_1.hh, output_txo_44_2.hh,
        output_txo_45_1.hh, output_txo_45_2.hh,
        output_txo_46_1.hh, output_txo_46_2.hh,
        output_txo_47_1.hh, output_txo_47_2.hh,
        output_txo_48_1.hh, output_txo_48_2.hh,
        output_txo_49_1.hh, output_txo_49_2.hh,
        output_txo_50_1.hh, output_txo_50_2.hh,
        output_txo_51_1.hh, output_txo_51_2.hh,
        output_txo_52_1.hh, output_txo_52_2.hh,
        output_txo_53_1.hh, output_txo_53_2.hh,
        output_txo_54_1.hh, output_txo_54_2.hh,
        output_txo_55_1.hh, output_txo_55_2.hh,
        output_txo_56_1.hh, output_txo_56_2.hh,
        output_txo_57_1.hh, output_txo_57_2.hh,
        output_txo_58_1.hh, output_txo_58_2.hh,
        output_txo_59_1.hh, output_txo_59_2.hh,
        output_txo_60_1.hh, output_txo_60_2.hh,
        output_txo_61_1.hh, output_txo_61_2.hh,
        output_txo_62_1.hh, output_txo_62_2.hh,
        output_txo_63_1.hh, output_txo_63_2.hh,
        output_txo_64_1.hh, output_txo_64_2.hh,
        output_txo_65_1.hh, output_txo_65_2.hh,
        output_txo_66_1.hh, output_txo_66_2.hh,
        output_txo_67_1.hh, output_txo_67_2.hh,
        output_txo_68_1.hh, output_txo_68_2.hh,
    ],
    root_9
)

with open(os.path.join(BUILD_PATH, 'rollUp9.json'), 'w+') as f:
    json.dump(roll_up_proof_9, f)

# Double spending withdraw
withdrawing_txo = output_txo_8_1
withdrawing_inclusion_proof = mmr.get_inclusion_proof(15)
r = withdrawing_txo.r
v = withdrawing_txo.v
zk_inclusion_proof = withdrawing_inclusion_proof.zk_proof(r, v)
zk_withdraw_proof = PedersenMMR.zk_withdraw_proof(root_9, 15, r, v, peaks_9, withdrawing_inclusion_proof.siblings)

with open(os.path.join(BUILD_PATH, 'doubleSpendingInclusion.json'), 'w+') as f:
    json.dump(zk_inclusion_proof, f)

with open(os.path.join(BUILD_PATH, 'doubleSpendingWithdraw.json'), 'w+') as f:
    json.dump(zk_withdraw_proof, f)

# Withdraw
withdrawing_txo = output_txo_68_1
withdrawing_inclusion_proof = mmr.get_inclusion_proof(135)
r = withdrawing_txo.r
v = withdrawing_txo.v
zk_inclusion_proof = withdrawing_inclusion_proof.zk_proof(r, v)
zk_withdraw_proof = PedersenMMR.zk_withdraw_proof(root_9, 135, r, v, peaks_9, withdrawing_inclusion_proof.siblings)

with open(os.path.join(BUILD_PATH, 'inclusion.json'), 'w+') as f:
    json.dump(zk_inclusion_proof, f)

with open(os.path.join(BUILD_PATH, 'withdraw.json'), 'w+') as f:
    json.dump(zk_withdraw_proof, f)
