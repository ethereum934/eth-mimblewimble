import json
import time
from functools import reduce
import docker
import random
from typing import List

from ethsnarks.field import SNARK_SCALAR_FIELD, FQ
from ethsnarks.pedersen import pedersen_hash_bits
from ethsnarks.jubjub import Point

from py934.jubjub import Field
from .constant import G, H


class Signature:
    def __init__(self, s: Field, R: Point):
        self.s = s
        self.R = R

    def __add__(self, other):
        assert isinstance(self, Signature)
        return Signature(self.s + other.s, self.R + other.R)


class Output:
    def __init__(self, r: Field, v: Field):
        hh = r * G + v * H
        assert hh.valid()
        self.hh = hh
        self.r = r
        self.v = v
        self._range_proof = None
        self._inclusion_proof = None
        self._deposit_proof = None  # Only for deposit TXO

    @property
    def public_key(self) -> Point:
        return self.r * G

    @property
    def private_key(self) -> Field:
        return self.r

    def __set_r(self, r: Field):
        self.r = r if isinstance(r, Field) else Field(int(r))
        assert self.r.n < SNARK_SCALAR_FIELD, "For light calculation, only use elements less than SNARK FIELD"
        if hasattr(self, 'v'):
            assert self.r * G + self.v * H == self.hh

    def __set_v(self, v: Field):
        self.v = v if isinstance(v, Field) else Field(int(v))
        assert self.v.n < SNARK_SCALAR_FIELD, "For light calculation, only use elements less than SNARK FIELD"
        if hasattr(self, 'r'):
            assert self.r * G + self.v * H == self.hh

    def __str__(self):
        return """
        r: {}
        v: {}
        commitment: ({}, {})
        """.format(self.r, self.v, self.hh.x, self.hh.y)

    @classmethod
    def new(cls, v: Field):
        # For a light-weight zk proof, pick random value between the zk SNARKs scalar field
        r = Field(random.randint(1, SNARK_SCALAR_FIELD))
        txo = cls(r, v)
        return txo

    @property
    def tag(self):
        tag_point = self.hh * self.r
        return tag_point.y

    @property
    def deposit_proof(self):
        if self._deposit_proof is None:
            client = docker.from_env()
            start = time.time()
            proof_bytes = client.containers.run("ethereum934/zk-deposit",
                                                environment={"args": " ".join(map(str, [
                                                    self.hh.y,  # public
                                                    self.v,
                                                    self.r,
                                                ]))})
            print('Calculated deposit proof in {} seconds'.format(time.time() - start))
            client.close()
            proof = json.loads(proof_bytes.decode('utf-8'))
            self._deposit_proof = proof

        return self._deposit_proof

    @property
    def range_proof(self):
        if self._range_proof is None:
            client = docker.from_env()
            start = time.time()
            proof_bytes = client.containers.run("ethereum934/zk-range-proof",
                                                environment={"args": " ".join(map(str, [
                                                    self.hh.y,  # public
                                                    self.r,
                                                    self.v,
                                                ]))})
            print('Calculated range proof in {} seconds'.format(time.time() - start))
            client.close()
            proof = json.loads(proof_bytes.decode('utf-8'))
            self._range_proof = proof

        return self._range_proof

    def compress(self):
        return self.hh.compress()


class Kernel:
    def __init__(self, hh_excess: Point, signature: Signature, fee, metadata):
        self.hh_excess = hh_excess
        self.signature = signature
        self.fee = fee
        self.metadata = metadata

    def __str__(self):
        return """
        excess:
        {}
        signature (scalar):
        {}
        signature (point):
        {}
        fee:
        {},
        metadata:
        {}
        """.format(self.hh_excess, self.signature.s.to_fq2(), self.signature.R, self.fee, self.metadata)


class Body:
    def __init__(self, hh_input_tags: List[FQ], hh_outputs: List[Point]):
        assert len(hh_input_tags) == 2
        self.hh_input_tags = hh_input_tags
        self.hh_outputs = hh_outputs

    def __str__(self):
        return """
        input tags:
        {}
        outputs:
        {}
        """.format(self.hh_input_tags, self.hh_outputs)


class Transaction:
    def __init__(self, kernel: Kernel, body: Body, range_proofs, inclusion_proofs, mimblewimble_proof):
        self.kernel = kernel
        self.body = body
        self.range_proofs = range_proofs
        self.inclusion_proofs = inclusion_proofs
        self.mimblewimble_proof = mimblewimble_proof

    @property
    def challenge(self):
        return Transaction.create_challenge(self.kernel.hh_excess, self.kernel.signature.R, self.kernel.fee,
                                            self.kernel.metadata)

    @staticmethod
    def create_challenge(hh_excess: Point, hh_sig_salt: Point, fee: Field, metadata: Field) -> Field:
        # Circuit uses big-endian while ethsnarks lib uses little-endian
        concatenated_source = \
            metadata.bits() + \
            fee.bits() + \
            hh_sig_salt.y.bits() + \
            hh_excess.y.bits()
        concatenated_source.reverse()
        assert len(concatenated_source) == 1016
        hashed_point = pedersen_hash_bits(b'Ethereum934', concatenated_source)
        return Field(hashed_point.y.n)

    @classmethod
    def new(cls,
            hh_excess: Point,
            signature: Signature,
            fee: Field,
            metadata: Field,
            outputs: List[Point],
            inputs: List[Output],  # This value will be hidden to others
            range_proofs: List,
            inclusion_proofs: List
            ):
        tags = [(item.r * item.hh).y for item in inputs]

        # check Mimblewimble
        # inputs[0].hh + inputs[1].hh + hh_excess = outputs[0] + outputs[1] + fee*H
        inflow_hidings = reduce((lambda hidings, txo: hidings + txo.hh), inputs, hh_excess)
        outflow_hidings = reduce((lambda hidings, hh: hidings + hh), outputs, fee * H)
        assert inflow_hidings == outflow_hidings

        # check Schnorr signature
        challenge = Transaction.create_challenge(hh_excess, signature.R, fee, metadata)
        assert signature.s * G == signature.R + challenge * hh_excess

        kernel = Kernel(hh_excess, signature, fee, metadata)
        body = Body(tags, outputs)
        range_proofs = range_proofs
        inclusion_proofs = inclusion_proofs

        client = docker.from_env()
        start = time.time()
        proof_bytes = client.containers.run("ethereum934/zk-mimblewimble",
                                            environment={"args": " ".join(map(str, [
                                                kernel.fee,  # public
                                                kernel.metadata,  # public
                                                *body.hh_input_tags,  # public
                                                body.hh_outputs[0].x,  # public
                                                body.hh_outputs[0].y,  # public
                                                body.hh_outputs[1].x,  # public
                                                body.hh_outputs[1].y,  # public
                                                kernel.signature.R,  # public
                                                kernel.hh_excess.x,
                                                kernel.hh_excess.y,
                                                *kernel.signature.s.to_fq2(),
                                                inputs[0].r,
                                                inputs[1].r,
                                                inputs[0].v,
                                                inputs[1].v
                                            ]))})
        print('Calculated mimblewimble proof in {} seconds'.format(time.time() - start))
        client.close()
        mw_proof = json.loads(proof_bytes.decode('utf-8'))
        return cls(kernel, body, range_proofs, inclusion_proofs, mw_proof)


class Request:
    def __init__(self,
                 value: Field,
                 fee: Field,
                 hh_sig_salt: Point,
                 hh_excess: Point,
                 metadata: Field
                 ):
        self.value = value
        self.fee = fee
        self.hh_sig_salt = hh_sig_salt  # Sender's nonce k_s * G
        self.hh_excess = hh_excess  # (r_change - r_input) * G
        self.metadata = metadata

    def __str__(self):
        str_to_print = """
        val: {}
        fee: {}
        public_sign: {}
        public_excess: {}
        metadata: {}
        """.format(self.value, self.fee, self.hh_sig_salt, self.hh_excess,
                   self.metadata)
        return str_to_print

    def serialize(self):
        serialized = b''
        serialized += self.value.to_bytes('little')
        serialized += self.fee.to_bytes('little')
        serialized += self.hh_sig_salt.compress()
        serialized += self.hh_excess.compress()
        serialized += self.metadata.to_bytes('little')
        return serialized

    @classmethod
    def deserialize(cls, serialized):
        assert len(serialized) == 32 * 5
        value = Field(int.from_bytes(serialized[0:32], 'little'))
        fee = Field(int.from_bytes(serialized[32:64], 'little'))
        sig_salt = Point.decompress(serialized[64:96])
        excess = Point.decompress(serialized[96:128])
        metadata = Field(int.from_bytes(serialized[128:160], 'little'))
        instance = cls(value, fee, sig_salt, excess, metadata)
        return instance


class Response:
    def __init__(self, hh_output: Point, hh_excess: Point, signature: Signature, range_proof):
        self.hh_output = hh_output
        self.hh_excess = hh_excess
        self.signature = signature
        self.range_proof = range_proof

    def __str__(self):
        str_to_print = """
        =============
        recipient's output key(hh): {}
        recipient's sig_salt(hh): {}
        recipient's signature: {}
        """.format(self.hh_output, self.signature.R, self.signature)
        return str_to_print

    def serialize(self):
        serialized = b''
        serialized += self.hh_output.compress()
        serialized += self.hh_excess.compress()
        serialized += self.signature.R.compress()
        serialized += self.signature.s.to_bytes('little')
        serialized += json.dumps(self.range_proof).encode('utf-8')
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
        range_proof = json.loads(serialized[96:].decode('utf-8'))
        instance = cls(hh_outputs, hh_excess, signature, range_proof)
        return instance


class SendTxBuilder:
    def __init__(self):
        self._metadata = Field(0)
        self._value = None
        self._fee = None
        self._inputs = []
        self._inclusion_proofs = []
        self._change = None
        self._sig_salt = None

    def value(self, _value: int):
        assert _value < SNARK_SCALAR_FIELD
        self._value = Field(_value)
        return self

    def fee(self, _fee: int):
        assert _fee < SNARK_SCALAR_FIELD
        self._fee = Field(_fee)
        return self

    def input_txo(self, _txo: Output, _inclusion_proof):
        self._inputs.append(_txo)
        self._inclusion_proofs.append(_inclusion_proof)
        assert len(self._inputs) <= 2, "You can only aggregate up to 2 TXOs"
        # TODO validate inclusion proof
        return self

    def change_txo(self, _change: Output):
        assert len(self._inputs) != 0
        inflow = reduce((lambda val, txo: val + txo.v), self._inputs, 0)
        outflow = self._value + self._fee + _change.v.n
        assert inflow == outflow, "Total sum does not change"
        assert self._change is None, "Change TXO already exists"
        self._change = _change
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
        if len(self._inputs) == 1:
            self._inputs.append(Output(Field(0), Field(0)))  # Dummy input txo
        assert len(self._inputs) == 2
        assert self._value is not None
        assert self._fee is not None
        assert self._change is not None
        assert self._metadata is not None
        assert self._sig_salt is not None
        return TxSend(self._value, self._fee, self._inputs, self._inclusion_proofs, self._change, self._metadata,
                      self._sig_salt)


class ReceiveTxBuilder:
    def __init__(self):
        self._request = None
        self._outputs = None
        self._sig_salt = None

    def request(self, request: Request):
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

    def __init__(
            self,
            value: Field,
            fee: Field,
            inputs: List[Output],
            inclusion_proofs,
            change: Output,
            metadata: Field,
            sig_salt: Field
    ):
        self.value = value
        self.fee = fee
        self.inputs = inputs
        self.inclusion_proofs = inclusion_proofs
        self.change = change
        self.metadata = metadata
        self.sig_salt = sig_salt
        self._request = None
        self._response = None
        self._builder = None
        inflow = reduce((lambda val, txo: val + txo.v), self.inputs, 0)
        assert inflow == value + fee + change.v.n, "Not enough input value"
        # TODO : validate proofs in inclusion_proofs:

    @property
    def excess(self):
        r_sum_of_inputs = reduce((lambda excess, txo: excess + txo.r), self.inputs, 0)
        return self.change.r - r_sum_of_inputs

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
        hh_excess = self.request.hh_excess + self.response.hh_excess
        aggregated_signature = self.signature + self.response.signature
        range_proofs = [self.change.range_proof, self.response.range_proof]
        return Transaction.new(
            hh_excess,
            aggregated_signature,
            self.fee,
            self.metadata,
            [self.change.hh, self.response.hh_output],
            self.inputs,
            range_proofs,
            self.inclusion_proofs
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
        return Response(self.output.hh, self.output.public_key, self.signature, self.output.range_proof)
