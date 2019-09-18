import unittest
from eth_account import Account

from py934.mimblewimble import TxSend, Output, Field, Request, TxReceive
from py934.mmr import PedersenMMR
import json
import os

BUILD_PATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'dataset')
class Secrets:
    pass


class TestMimblewimble(unittest.TestCase):
    def setUp(self):
        self.sender_secrets = Secrets()
        self.receiver_secrets = Secrets()
        self.shared_secrets = Secrets()

        value = Field.random(100, 500)
        fee = Field(10)
        input_txo = Output.new(Field.random(1000, 10000))
        change_txo = Output.new(input_txo.v - fee - value)
        sender_sig_salt = Field.random()
        output_txo = Output.new(value)
        receiver_sig_salt = Field.random()
        metadata = "Ethereum934"
        self.mmr = PedersenMMR()
        self.mmr.append(input_txo.hh)
        self.shared_secrets.value = value
        self.shared_secrets.fee = fee
        self.shared_secrets.metadata = metadata
        self.sender_secrets.deposit_txo = input_txo
        self.sender_secrets.input_txo = input_txo
        self.sender_secrets.change_txo = change_txo
        self.sender_secrets.sig_salt = sender_sig_salt
        self.sender_secrets.inclusion_proof = self.mmr.get_inclusion_proof(1).zk_proof(input_txo.r, input_txo.v)
        self.receiver_secrets.output_txo = output_txo
        self.receiver_secrets.sig_salt = receiver_sig_salt
        self.sender = Account.mro()

    def test_transaction(self):
        # Sender prepares TxSend
        tx_send = TxSend.builder(). \
            value(self.shared_secrets.value). \
            fee(self.shared_secrets.fee). \
            input_txo(self.sender_secrets.input_txo, self.sender_secrets.inclusion_proof). \
            change_txo(self.sender_secrets.change_txo). \
            metadata(self.shared_secrets.metadata). \
            sig_salt(self.sender_secrets.sig_salt). \
            build()

        # Sender serializes and encrypt with recipient's public key

        serialized_request = tx_send.request.serialize()

        # Receiver prepares TxReceive and reply response
        deserialized_request = Request.deserialize(serialized_request)
        self.assertEqual(deserialized_request.value, tx_send.request.value)
        self.assertEqual(deserialized_request.fee, tx_send.request.fee)
        self.assertEqual(deserialized_request.hh_sig_salt, tx_send.request.hh_sig_salt)
        self.assertEqual(deserialized_request.hh_excess, tx_send.request.hh_excess)
        self.assertEqual(deserialized_request.metadata, tx_send.request.metadata)
        tx_receive = TxReceive.builder(). \
            request(deserialized_request). \
            output_txo(self.receiver_secrets.output_txo). \
            sig_salt(self.receiver_secrets.sig_salt). \
            build()
        response = tx_receive.response

        # Sender completes a transaction by merging the response
        transaction = tx_send.merge(response)
        self.assertIsNotNone(transaction)
        with open(os.path.join(BUILD_PATH, 'transaction.json'), 'w+') as file:
            json.dump(transaction.to_dict(), file)

    def test_range_proof(self):
        range_proof = self.sender_secrets.input_txo.range_proof
        self.assertIsNotNone(range_proof)
        with open(os.path.join(BUILD_PATH, 'range_proof.json'), 'w+') as file:
            json.dump(range_proof, file)

    def test_deposit_proof(self):
        deposit_proof = self.sender_secrets.deposit_txo.deposit_proof
        self.assertIsNotNone(deposit_proof)
        with open(os.path.join(BUILD_PATH, 'deposit_proof.json'), 'w+') as file:
            json.dump(deposit_proof, file)


if __name__ == '__main__':
    unittest.main()
