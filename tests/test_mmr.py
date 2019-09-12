import unittest

from py934.constant import G
from py934.mimblewimble import Field
from py934.mmr import PedersenMMR


class TestMMR(unittest.TestCase):
    def test_append(self):
        x_peaks = []
        y_peaks = []
        item_1 = Field(1) * G
        item_2 = Field(2) * G
        item_3 = Field(3) * G
        item_4 = Field(4) * G
        item_5 = Field(5) * G
        item_6 = Field(6) * G
        mmr = PedersenMMR()
        mmr.append(item_1)
        mmr.append(item_2)
        mmr.append(item_3)
        mmr.append(item_4)
        for peak in mmr.peaks:
            x_peaks.append(peak.x.n)
            y_peaks.append(peak.y.n)
        print("4")
        print(mmr.root)
        print(x_peaks)
        print(y_peaks)
        mmr.append(item_5)
        mmr.append(item_6)
        x_peaks = []
        y_peaks = []
        for peak in mmr.peaks:
            x_peaks.append(peak.x.n)
            y_peaks.append(peak.y.n)
        print("6")
        print(mmr.root)
        print(x_peaks)
        print(y_peaks)
        proof = mmr.get_inclusion_proof(2)
        x_sib = []
        y_sib = []
        for sib in proof.siblings:
            x_sib.append(sib.x.n)
            y_sib.append(sib.y.n)
        print('sibligns')
        print(x_sib)
        print(y_sib)
        print('item')
        print(item_2)


if __name__ == '__main__':
    unittest.main()
