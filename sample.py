from py934.mimblewimble import TxSend, Output, Field, TxReceive, Transaction
from py934.mmr import PedersenMMR
import json
import copy
import os

BUILD_PATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'build')


def make_tx(input_txo: Output, proof) -> (Transaction, Output, Output):
    fee = Field.random(1, 100)
    value = Field.random(1000, input_txo.v - fee)
    output_txo_1 = Output.new(value)
    output_txo_2 = Output.new(input_txo.v - fee - value)
    tx_send = TxSend.builder(). \
        value(value). \
        fee(fee). \
        input_txo(input_txo, proof). \
        change_txo(output_txo_2). \
        metadata(100). \
        sig_salt(Field.random()). \
        build()
    tx_receive = TxReceive.builder(). \
        request(tx_send). \
        output_txo(output_txo_1). \
        sig_salt(Field.random()). \
        build()
    tx = tx_send.merge(tx_receive.response)
    return tx, output_txo_1, output_txo_2


mmr = PedersenMMR()
root_0 = copy.deepcopy(mmr.root)
width_0 = copy.deepcopy(mmr.width)
peaks_0 = copy.deepcopy(mmr.peaks)

# Deposit
deposit_txo_1 = Output.new(Field.random(10000, 100000))
deposit_txo_2 = Output.new(Field.random(10000, 100000))
with open(os.path.join(BUILD_PATH, 'deposit1.json'), 'w+') as f:
    json.dump(deposit_txo_1.deposit_proof, f)
with open(os.path.join(BUILD_PATH, 'deposit2.json'), 'w+') as f:
    json.dump(deposit_txo_2.deposit_proof, f)

# Tx Round 1
input_txo_1 = deposit_txo_1
input_txo_2 = deposit_txo_2
tx_1, output_txo_1_1, output_txo_1_2 = make_tx(input_txo_1, None)
tx_2, output_txo_2_1, output_txo_2_2 = make_tx(input_txo_2, None)

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

# Tx Round 2
input_txo_3 = output_txo_1_1
input_txo_4 = output_txo_2_2

input_txo_3_inclusion_proof = mmr.get_inclusion_proof(1)
input_txo_4_inclusion_proof = mmr.get_inclusion_proof(4)
zk_inclusion_proof_input_txo_3 = input_txo_3_inclusion_proof.zk_proof(input_txo_3.r, input_txo_3.v)
zk_inclusion_proof_input_txo_4 = input_txo_4_inclusion_proof.zk_proof(input_txo_4.r, input_txo_4.v)

tx_3, output_txo_3_1, output_txo_3_2 = make_tx(input_txo_3, zk_inclusion_proof_input_txo_3)
tx_4, output_txo_4_1, output_txo_4_2 = make_tx(input_txo_4, zk_inclusion_proof_input_txo_4)

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

# Withdraw
inclusion_proof = mmr.get_inclusion_proof(8)
zk_inclusion_proof = inclusion_proof.zk_proof(output_txo_4_2.r, output_txo_4_2.v)

with open(os.path.join(BUILD_PATH, 'inclusion_proof.json'), 'w+') as f:
    json.dump(zk_inclusion_proof, f)
