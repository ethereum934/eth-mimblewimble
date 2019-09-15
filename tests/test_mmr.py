import unittest

from py934.constant import G, H
from py934.mimblewimble import Field
from py934.mmr import PedersenMMR


class TestMMR(unittest.TestCase):
    def setUp(self):
        txo1 = Field(1) * G + Field(11) * H
        txo2 = Field(2) * G + Field(12) * H
        txo3 = Field(3) * G + Field(13) * H
        txo4 = Field(4) * G + Field(14) * H
        txo5 = Field(5) * G + Field(15) * H
        txo6 = Field(6) * G + Field(16) * H
        self.mmr = PedersenMMR()
        self.mmr.append(txo1)
        self.mmr.append(txo2)
        self.mmr.append(txo3)
        self.mmr.append(txo4)
        self.mmr.append(txo5)
        self.mmr.append(txo6)

    def test_zk_inclusion_proof(self):
        proof = None
        try:
            inclusion_proof = self.mmr.get_inclusion_proof(3)
            proof = inclusion_proof.zk_proof(Field(3), Field(13))
        finally:
            assert proof is not None
            # TODO test with VM

    def test_zk_withdraw_proof(self):
        proof = None
        root = self.mmr.root
        position = 3
        r = Field(3)
        v = Field(13)
        peaks = self.mmr.peaks
        siblings = self.mmr.get_siblings(3)
        try:
            proof = PedersenMMR.zk_withdraw_proof(root, position, r, v, peaks, siblings)
        finally:
            assert proof is not None
            # TODO test with VM

    def test_zk_roll_up_proof(self):
        current_root = self.mmr.root
        current_width = self.mmr.width
        current_peaks = self.mmr.peaks
        mmr = PedersenMMR.from_peaks(16, self.mmr.peaks)
        items_to_update = [
            Field(7) * G + Field(17) * H,
            Field(8) * G + Field(18) * H,
            Field(9) * G + Field(19) * H,
            Field(10) * G + Field(20) * H,
            Field(11) * G + Field(21) * H,
            Field(12) * G + Field(22) * H,
            Field(13) * G + Field(23) * H,
            Field(14) * G + Field(24) * H,
            Field(15) * G + Field(25) * H,
            Field(16) * G + Field(26) * H,
            Field(17) * G + Field(27) * H,
            Field(18) * G + Field(28) * H,
            Field(19) * G + Field(29) * H,
            Field(20) * G + Field(30) * H,
            Field(21) * G + Field(31) * H,
            Field(22) * G + Field(32) * H,
        ]
        for item in items_to_update:
            mmr.append(item)
        new_root = mmr.root
        proof = None
        try:
            proof = PedersenMMR.zk_roll_up_proof(current_root, current_width, current_peaks, items_to_update, new_root)
        finally:
            assert proof is not None
            # TODO test with VM


if __name__ == '__main__':
    unittest.main()
