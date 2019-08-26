import unittest
from eth_account import Account

from py934.constant import H
from py934.transaction import TxSend, Output, Field, Request, TxReceive


class Secrets:
    pass


class TestTransactions(unittest.TestCase):
    def setUp(self):
        self.sender_secrets = Secrets()
        self.receiver_secrets = Secrets()
        self.shared_secrets = Secrets()

        value = Field.random(100, 500)
        fee = Field(10)
        inputs = Output.new(Field.random(1000, 10000))
        changes = Output.new(inputs.v - fee - value)
        sender_sig_salt = Field.random()
        outputs = Output.new(value)
        receiver_sig_salt = Field.random()
        self.shared_secrets.value = value
        self.shared_secrets.fee = fee
        self.shared_secrets.metadata = 'Ethereum934'
        self.sender_secrets.inputs = inputs
        self.sender_secrets.changes = changes
        self.sender_secrets.sig_salt = sender_sig_salt
        self.receiver_secrets.outputs = outputs
        self.receiver_secrets.sig_salt = receiver_sig_salt
        self.sender = Account.mro()

    def test_transaction(self):
        # Sender prepares TxSend
        tx_send = TxSend.builder(). \
            value(self.shared_secrets.value). \
            fee(self.shared_secrets.fee). \
            input_txo(self.sender_secrets.inputs). \
            change_txo(self.sender_secrets.changes). \
            metadata(self.shared_secrets.metadata). \
            sig_salt(self.sender_secrets.sig_salt). \
            build()

        # Sender serializes and encrypt with recipient's public key

        serialized_request = tx_send.request.serialize()

        # Receiver prepares TxReceive and reply response
        deserialized_request = Request.deserialize(serialized_request)
        self.assertEqual(deserialized_request.value, tx_send.request.value)
        self.assertEqual(deserialized_request.fee, tx_send.request.fee)
        self.assertEqual(deserialized_request.hh_inputs, tx_send.request.hh_inputs)
        self.assertEqual(deserialized_request.hh_changes, tx_send.request.hh_changes)
        self.assertEqual(deserialized_request.hh_sig_salt, tx_send.request.hh_sig_salt)
        self.assertEqual(deserialized_request.hh_excess, tx_send.request.hh_excess)
        self.assertEqual(deserialized_request.metadata, tx_send.request.metadata)
        tx_receive = TxReceive.builder(). \
            request(deserialized_request). \
            output_txo(self.receiver_secrets.outputs). \
            sig_salt(self.receiver_secrets.sig_salt). \
            build()
        response = tx_receive.response

        # Sender completes a transaction by merging the response
        transaction = tx_send.merge(response)
        self.assertIsNotNone(transaction)


if __name__ == '__main__':
    unittest.main()
