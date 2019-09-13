import random
from ethsnarks.field import SNARK_SCALAR_FIELD, FR, FQ
from ethsnarks.jubjub import Point


class Field(FR):
    def __mul__(self, other):
        if isinstance(other, Point):
            if self.n >= SNARK_SCALAR_FIELD:
                a = other * (SNARK_SCALAR_FIELD - 1)
                b = other * (self.n + 1 - SNARK_SCALAR_FIELD)
                return a + b
            else:
                return other * self.n
        else:
            return Field(FR.__mul__(self, other).n)

    def __add__(self, other):
        return Field(FR.__add__(self, other).n)

    def __radd__(self, other):
        return self.__add__(other)

    def __sub__(self, other):
        return Field(FR.__sub__(self, other).n)

    def __rsub__(self, other):
        return self.__sub__(other)

    def __lt__(self, other):
        return int(self) < int(other)

    def __le__(self, other):
        return int(self) <= int(other)

    def __gt__(self, other):
        return int(self) > int(other)

    def __ge__(self, other):
        return int(self) >= int(other)

    @classmethod
    def random(cls, start=1, end=SNARK_SCALAR_FIELD):
        assert 0 <= start and end <= SNARK_SCALAR_FIELD
        return cls(random.randint(start, end))

    def to_fq2(self):
        if self.n > SNARK_SCALAR_FIELD:
            return [FQ(SNARK_SCALAR_FIELD), FQ(self.n)]
        else:
            return [FQ(self.n), FQ(0)]
