import unittest

from ethsnarks.field import FR_ORDER

from py934.constant import G
from py934.mimblewimble import Field


class TestField(unittest.TestCase):
    def test_field_modulus(self):
        self.assertEqual(Field(0) - 1, FR_ORDER - 1, msg="Modulus test")

    def test_cycle(self):
        a = Field(0) - 1
        b = Field(3)
        self.assertEqual((a+b), Field(2), msg="Cycle test")

    def test_pedersen_commitment(self):
        a = Field(0) - 1
        b = Field(3)
        self.assertEqual((a+b)*G, a*G + b*G, msg="Pedersen Commitment test")


if __name__ == '__main__':
    unittest.main()
