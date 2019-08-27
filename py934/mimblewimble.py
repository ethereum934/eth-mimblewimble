import random
from typing import List

from ethsnarks.field import SNARK_SCALAR_FIELD
from ethsnarks.pedersen import pedersen_hash_bits
from ethsnarks.jubjub import Point
from bitstring import BitArray

from py934.jubjub import Field
from .constant import G, H


class Signature:
    def __init__(self, s, R):
        self.s = s
        self.R = R

    def __add__(self, other):
        assert isinstance(self, Signature)
        return Signature(self.s + other.s, self.R + other.R)


class Kernel:
    def __init__(self, hh_excess, signature: Signature, fee, metadata):
        self.hh_excess = hh_excess
        self.signature = signature
        self.fee = fee
        self.metadata = metadata


class Body:
    def __init__(self, hh_inputs, hh_outputs: List[Point]):
        self.hh_inputs = hh_inputs
        self.hh_outputs = hh_outputs


class Transaction:
    def __init__(self,
                 hh_excess: Point,
                 signature: Signature,
                 fee: Field,
                 metadata: Field,
                 hh_inputs: Point,
                 hh_changes: Point,
                 hh_outputs: Point
                 ):
        self.kernel = Kernel(hh_excess, signature, fee, metadata)
        self.body = Body(hh_inputs, [hh_changes, hh_outputs])

        # check MimbleWimble
        assert hh_inputs + hh_excess == hh_changes + hh_outputs + fee * H

        # check Schnorr signature
        challenge = self.create_challenge(hh_excess, signature.R, fee, metadata)
        assert signature.s * G == signature.R + challenge * hh_excess

    @property
    def challenge(self):
        challenge = self.create_challenge(self.hh_excess, self.signature.R, self.fee, self.metadata)
        return challenge

    @classmethod
    def create_challenge(cls, hh_excess: Point, hh_sig_salt: Point, fee: Field, metadata: Field):
        concatenated_source = \
            BitArray(hex=hh_excess.compress().hex()) + \
            BitArray(hex=hh_sig_salt.compress().hex()) + \
            fee.bits() + \
            metadata.bits()
        assert len(concatenated_source) == 1020
        hashed_point = pedersen_hash_bits(b'934', concatenated_source)
        hashed = int.from_bytes(hashed_point.compress(), 'little')
        return Field(hashed)


class Output:
    def __init__(self, pedersen_commitment: Point):
        assert pedersen_commitment.valid()
        self.pedersen_commitment = pedersen_commitment

    @property
    def public_key(self) -> Point:
        if self.r is not None:
            return self.r * G
        elif self.v is not None:
            return self.pedersen_commitment - self.v * H
        else:
            raise ValueError("Does not have the private key")

    @property
    def private_key(self) -> Field:
        if self.r is not None:
            return self.r
        else:
            raise ValueError("Does not have private key")

    def __set_r(self, r: Field):
        self.r = r if isinstance(r, Field) else Field(int(r))
        assert self.r.n < SNARK_SCALAR_FIELD, "For light calculation, only use elements less than SNARK FIELD"
        if hasattr(self, 'v'):
            assert self.r * G + self.v * H == self.pedersen_commitment

    def __set_v(self, v: Field):
        self.v = v if isinstance(v, Field) else Field(int(v))
        assert self.v.n < SNARK_SCALAR_FIELD, "For light calculation, only use elements less than SNARK FIELD"
        if hasattr(self, 'r'):
            assert self.r * G + self.v * H == self.pedersen_commitment

    def __str__(self):
        return """
        r: {}
        v: {}
        commitment: ({}, {})
        """.format(self.r, self.v, self.pedersen_commitment.x, self.pedersen_commitment.y)

    @classmethod
    def new(cls, v: Field):
        # For a light-weight zk proof, pick random value between the zk SNARKs scalar field
        r = Field(random.randint(1, SNARK_SCALAR_FIELD))
        pedersen_commitment = r * G + v * H
        txo = cls(pedersen_commitment)
        txo.__set_r(r)
        txo.__set_v(v)
        return txo

    @classmethod
    def from_secrets(cls, r: int, v: int):
        r = Field(r)
        v = Field(v)
        pedersen_commitment = r * G + v * H
        txo = cls(pedersen_commitment)
        txo.__set_r(r)
        txo.__set_v(v)
        return txo

    @classmethod
    def from_public_key_with_value(cls, rG: Point, v: Field):
        assert v.n <= SNARK_SCALAR_FIELD
        pedersen_commitment = rG + v * H
        txo = cls(pedersen_commitment)
        txo.__set_v(v)
        return txo

    @classmethod
    def from_compressed(cls, compressed: int):
        return cls(Point.decompress(compressed))

    def compress(self):
        return self.pedersen_commitment.compress()


class Request:
    def __init__(self,
                 value: Field,
                 fee: Field,
                 hh_inputs: Point,
                 hh_changes: Point,
                 hh_sig_salt: Point,
                 hh_excess: Point,
                 metadata: Field
                 ):
        self.value = value
        self.fee = fee
        self.hh_inputs = hh_inputs
        self.hh_changes = hh_changes
        self.hh_sig_salt = hh_sig_salt  # Sender's nonce k_s * G
        self.hh_excess = hh_excess  # (r_change - r_input) * G
        self.metadata = metadata

    def __str__(self):
        str_to_print = """
        val: {}
        fee: {}
        inputs: {}
        changes: {}
        public_sign: {}
        public_excess: {}
        metadata: {}
        """.format(self.value, self.fee, self.hh_inputs, self.hh_changes, self.hh_sig_salt, self.hh_excess,
                   self.metadata)
        return str_to_print

    def valid(self):
        return Request.validate(self.hh_excess, self.hh_inputs, self.hh_changes, self.value, self.fee)

    @staticmethod
    def validate(excess: Point, inputs: Point, changes: Point, value: Field, fee: Field):
        """
        X = (r_out - r_in)*G
        X + (v_out - v_in)*H = (r_out - r_in)*G + (v_out - v_in)*H
        X + (v_out - v_in)*H = (r_out*G + v_out*H) - (r_in*G + v_in*H)
        X - (value+fee)*H = changes - inputs
        X + inputs == changes + (value+fee)H
        """
        return excess + inputs == H * (value + fee) + changes

    def serialize(self):
        serialized = b''
        serialized += self.value.to_bytes('little')
        serialized += self.fee.to_bytes('little')
        serialized += self.hh_inputs.compress()
        serialized += self.hh_changes.compress()
        serialized += self.hh_sig_salt.compress()
        serialized += self.hh_excess.compress()
        serialized += self.metadata.to_bytes('little')
        return serialized

    @classmethod
    def deserialize(cls, serialized):
        assert len(serialized) == 32 * 7
        value = Field(int.from_bytes(serialized[0:32], 'little'))
        fee = Field(int.from_bytes(serialized[32:64], 'little'))
        inputs = Point.decompress(serialized[64:96])
        changes = Point.decompress(serialized[96:128])
        sig_salt = Point.decompress(serialized[128:160])
        excess = Point.decompress(serialized[160:192])
        metadata = Field(int.from_bytes(serialized[192:224], 'little'))
        instance = cls(value, fee, inputs, changes, sig_salt, excess, metadata)
        assert instance.valid()
        return instance


class Response:
    def __init__(self, hh_outputs: Point, hh_excess: Point, signature: Signature):
        self.hh_outputs = hh_outputs
        self.hh_excess = hh_excess
        self.signature = signature

    def __str__(self):
        str_to_print = """
        =============
        recipient's output key(hh): {}
        recipient's sig_salt(hh): {}
        recipient's signature: {}
        """.format(self.hh_outputs, self.signature.R, self.signature)
        return str_to_print

    def serialize(self):
        serialized = b''
        serialized += self.hh_outputs.compress()
        serialized += self.hh_excess.compress()
        serialized += self.signature.R.compress()
        serialized += self.signature.s.to_bytes('little')
        return serialized

    @classmethod
    def deserialize(cls, serialized):
        assert len(serialized) == 32 * 3
        hh_outputs = Point.decompress(serialized[0:32])
        hh_excess = Point.decompress(serialized[32:64])
        signature = Signature(
            Field(int.from_bytes(serialized[96:128], 'little')),
            Point.decompress(serialized[64:96])
        )
        instance = cls(hh_outputs, hh_excess, signature)
        return instance


class SendTxBuilder:
    def __init__(self):
        self._metadata = Field(0)
        self._value = None
        self._fee = None
        self._inputs = None
        self._changes = None
        self._sig_salt = None

    def value(self, _value: int):
        assert _value < SNARK_SCALAR_FIELD
        self._value = Field(_value)
        return self

    def fee(self, _fee: int):
        assert _fee < SNARK_SCALAR_FIELD
        self._fee = Field(_fee)
        return self

    def input_txo(self, _inputs: Output):
        self._inputs = _inputs
        return self

    def change_txo(self, _changes: Output):
        assert self._inputs is not None
        assert self._inputs.v.n == self._value + self._fee + _changes.v.n
        self._changes = _changes
        return self

    def metadata(self, _metadata):
        if isinstance(_metadata, Field):
            _metadata = _metadata
        elif isinstance(_metadata, int):
            pass
        elif isinstance(_metadata, str):
            _metadata = int.from_bytes(_metadata.encode(), byteorder='little')
        elif isinstance(_metadata, bytes):
            _metadata = int.from_bytes(_metadata, byteorder='little')
        else:
            raise TypeError('{} is not a supported type'.format(type(_metadata)))

        assert _metadata < SNARK_SCALAR_FIELD
        self._metadata = Field(_metadata)
        return self

    def sig_salt(self, _sig_salt: int):
        assert _sig_salt < SNARK_SCALAR_FIELD
        self._sig_salt = Field(_sig_salt)
        return self

    def build(self):
        assert self._value is not None
        assert self._fee is not None
        assert self._inputs is not None
        assert self._changes is not None
        assert self._metadata is not None
        assert self._sig_salt is not None
        return TxSend(self._value, self._fee, self._inputs, self._changes, self._metadata, self._sig_salt)


class ReceiveTxBuilder:
    def __init__(self):
        self._request = None
        self._outputs = None
        self._sig_salt = None

    def request(self, request: Request):
        assert request.valid()
        self._request = request
        return self

    def output_txo(self, _outputs: Output):
        assert self._request.value == _outputs.v
        self._outputs = _outputs
        return self

    def sig_salt(self, _sig_salt: int):
        assert _sig_salt < SNARK_SCALAR_FIELD
        self._sig_salt = _sig_salt
        return self

    def build(self):
        assert self._outputs is not None
        assert self._sig_salt is not None
        return TxReceive(self._request, self._outputs, self._sig_salt)


class TxSend:
    @classmethod
    def builder(cls):
        return SendTxBuilder()

    def __init__(self, value: Field, fee: Field, hh_inputs: Output, hh_changes: Output, metadata: Field,
                 sig_salt: Field):
        self.value = value
        self.fee = fee
        self.hh_inputs = hh_inputs
        self.hh_changes = hh_changes
        self.metadata = metadata
        self.sig_salt = sig_salt
        self._request = None
        self._response = None
        self._builder = None
        assert hh_inputs.v.n == value + fee + hh_changes.v.n, "Not enough input value"

    @property
    def excess(self):
        return self.hh_changes.r - self.hh_inputs.r

    @property
    def hh_excess(self):
        return self.excess * G

    @property
    def hh_sig_salt(self):
        return self.sig_salt * G

    @property
    def request(self):
        # public_excess: X = 0*H + excess *G
        # public_sign of Alice : R_a = r_a*G
        if self._request is None:
            self._request = Request(
                self.value,
                self.fee,
                self.hh_inputs.pedersen_commitment,
                self.hh_changes.pedersen_commitment,
                self.hh_sig_salt,
                self.hh_excess,
                self.metadata
            )
        return self._request

    def merge(self, response: Response):
        self._response = response
        return self.transaction

    @property
    def response(self) -> Response:
        return self._response

    @property
    def challenge(self):
        assert self._response is not None, "To get the challenge data, you should merge the recipient response first"
        request = self.request
        response = self.response
        return Transaction.create_challenge(
            request.hh_excess + response.hh_excess,
            request.hh_sig_salt + response.signature.R,
            request.fee, request.metadata
        )

    @property
    def signature(self) -> Signature:
        return Signature(self.sig_salt + self.challenge * self.excess, self.hh_sig_salt)

    @property
    def transaction(self):
        assert self.response is not None, "You should merge response from the recipient first"
        aggregated_signature = self.signature + self.response.signature
        return Transaction(
            self.request.hh_excess + self.response.hh_excess,
            aggregated_signature,
            self.fee,
            self.metadata,
            self.request.hh_inputs,
            self.request.hh_changes,
            self.response.hh_outputs
        )


class TxReceive:
    @classmethod
    def builder(cls):
        return ReceiveTxBuilder()

    def __init__(self, request: Request, output: Output, sig_salt: Field):
        self.request = request
        self.output = output
        self.sig_salt = sig_salt

    @property
    def challenge(self):
        challenge = Transaction.create_challenge(
            self.request.hh_excess + self.output.public_key,
            self.request.hh_sig_salt + self.sig_salt * G,
            self.request.fee, self.request.metadata
        )
        return challenge

    @property
    def signature(self) -> Signature:
        return Signature(self.sig_salt + self.challenge * self.output.r, self.sig_salt * G)

    @property
    def response(self):
        return Response(self.output.pedersen_commitment, self.output.public_key, self.signature)
