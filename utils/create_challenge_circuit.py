from zokrates_pycrypto.field import FQ
from zokrates_pycrypto.gadgets.pedersenHasher import PedersenHasher
from bitstring import BitArray


def to_254_bits(val: int):
    binary = BitArray(uint=val, length=254).bin
    return binary


def to_256_bits(val: int):
    binary = BitArray(uint=val, length=256).bin
    return binary


if __name__ == "__main__":
    hasher = PedersenHasher(b'Ethereum934')
    # To make concatenated length 1524 bit
    concatenated_source = \
        to_254_bits(3) + \
        to_254_bits(4) + \
        to_254_bits(5) + \
        to_254_bits(6)
    hashed_bytes = hasher.hash_bits(concatenated_source)
    hashed = int.from_bytes(hashed_bytes.compress(), 'big')
    # print(hasher.dsl_code, end='') # This generates pedersen hash circuit code
    hasher.write_dsl_code('challengeHasher.zok')
    print("Saved challengeHasher.zok")
