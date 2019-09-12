// This file is LGPL3 Licensed

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        uint256 pt1zx = 1;
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
        }

        uint256[6] memory pt2 = _ECTwistMulJacobian(
            s,
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            pt1zx, 0
        );

        return _fromJacobian(
            pt2[PTXX], pt2[PTXY],
            pt2[PTYX], pt2[PTYY],
            pt2[PTZX], pt2[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Add(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            addmod(xx, yx, FIELD_MODULUS),
            addmod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Div(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas, 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX], pt2[PTXY],
                    pt2[PTYX], pt2[PTYY],
                    pt2[PTZX], pt2[PTZY],
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy);
            }
            (
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            ) = _ECTwistDoubleJacobian(
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            );

            d = d / 2;
        }
    }
}
// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.5.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2) internal returns (G2Point memory r) {
        (r.X[1], r.X[0], r.Y[1], r.Y[0]) = BN256G2.ECTwistAdd(p1.X[1],p1.X[0],p1.Y[1],p1.Y[0],p2.X[1],p2.X[0],p2.Y[1],p2.Y[0]);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.a = Pairing.G1Point(uint256(0x205467e67974bdb30595fc7d20eca20a5c3df38f43a454772857d4a70466335d), uint256(0x2d3a96f5bcb3f46203f919724231530b5c661b662b97bfc8cb3a80fbfd6d6b67));
        vk.b = Pairing.G2Point([uint256(0x1505ff4c6787a0cd15c16a56ac81e000ac3d3aae141274dfdc9f834bf52aeee4), uint256(0x27543b414b8df63ad50c9b98d44aaab6da881f836da33f3fbb45b1150ea7ad73)], [uint256(0x2877b967586e6952a6e77f25779ebad4504e75dbc322765acfd173a20cc90370), uint256(0x2fdcc3e5a47bdd5f8c937ec0ed9c54fcc2149e045ce60d973fcc7ed01d2116d8)]);
        vk.gamma = Pairing.G2Point([uint256(0x2bc0acb578141456f7a725b202459b3158d2b53846159067aaae393d923efc75), uint256(0x16e4e52b37ce3c11655131f034b0cc399f527c1c0889615c47c80ac734416d39)], [uint256(0x1d2b41a675d244a9c22bbf0372cc6888eb66bb6da98782bf19ca1a5ee7807ad0), uint256(0x1e47fb9954c1eaabad630ae4741f5d11a44dc022b479085a4a82406326ead57b)]);
        vk.delta = Pairing.G2Point([uint256(0x2fa48df00165fda2ac39c33077140b21997441e55eb2aec794eaebd6a3fa114d), uint256(0x29852548e20635ecc47847e30be02961aba5131ba9b84ffdd4ed1c07da33584f)], [uint256(0x0016ba00eeee57b76991de8710e704705920cec01242ac6349268566c9daadea), uint256(0x0c9cd6c25351b2a9842928663027412cbe5bed4440d810e181282da2b0d03be3)]);
        vk.gamma_abc = new Pairing.G1Point[](69);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x06190ace128bf6baed96fccd2613adb9301d137190df71a33b32a681905313d8), uint256(0x11cf99cba19b26eb4207a83759b1dba88005eede47e09702a86824cc87fbdb41));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x254ca98b282eee4e182bd8de280eeb217af411c7c2873e8e70f9d2806e5c44a9), uint256(0x1d2d944ac3a211c0d473f4f19843c8e0c4b292cb602ae1c035c6434be7915f03));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0f0a5c782c4147961f3aa7cd13f86b990001050656d2fe311278eb394b617607), uint256(0x0a9510b58e6105c77db22b300433568aa6502145388660420e3702994bfd4879));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x068e2d90bf029eca7aca2e81ddec665247b839682bb99b260aa5602e81ab86f9), uint256(0x160e9c3b372ddd3d56a02cfa033fc75e451efb287d961d638bf6e468d09cf388));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0c0a64aefacc91728e47485cfc9c51fe9be7ef60b96c20619a6349b3326d357f), uint256(0x1fa6c12d23208c555edf9b0d00a7ef419e2a6f4bbc7fed636d4537ef992da327));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1507adec5c78d7b80038187ee9c976ebfab9e7de98f50fc614fcfbff862690db), uint256(0x138e746f3f331f30bb74afc155d1734fdd53efb809881774bdbebf7f11ce9da5));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0084d5dced373dba4018a665c9205d2abaf1515bb5d71627ad79ff7cb8480a04), uint256(0x1b080f3c48f9b5ce0edc011c10759bceb3081b2978288999a0f17f8a9a3a8eeb));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1fa44b0371b366c75ffc017813844ab7a20633dcff46b5e03c0c1869e096421e), uint256(0x29d90ea83f2932b5631b2d887e220eb21a4088c27096045f9aaaa2c4d61481eb));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2e70a33a9cacbcfc7e73ef04b42749bd47548228413becc049fcb238c7704e22), uint256(0x023251889bf953f163622ce80784fe070144acc7044a45001ba213d6bdb3e729));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2062bab2b44aa7a31f76bfa5e074ce4a2b87b967b0fd3fdee342e4cd4e8e3b47), uint256(0x08cd90481bd397c5e8634e4dcdb452ae8dd31e17edb5f462fc9443b29975bafc));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2c841101eb717eb686116541457a992ea6c8488e944509262fd474ddb3a2db3a), uint256(0x103f89e0ea0b28646b7bfb9645857e2f7791078b1c16d29b1103baec8024b4e4));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x221505d6e561a01a3d612397b9b6f74fa1254e1fa1345033b0ef4b5d1508b82d), uint256(0x22e763c2593087a302dcaf52b8dd15075443f693bb1579a7e01eefc8fef98642));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x1182449ee8ba89f708b08488075b07c4fc737211f7997f275748b05186e0db8c), uint256(0x2d293f5e796938800083c1481f0796ab1ff7f190f7aca1a91551deea6d98f9cf));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x0762312a34d55e4236fb8637c17cdf2beb6d385241d88c485cd6cd0b18adddd1), uint256(0x2330d534e7fd6428632ecf276e511ef37cfb4eb2d9d4b6ce4f58c519402629e6));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x2452b34fa19d46589721bf343e42f455bfd98185741e5e3b3068aa69d8e477a7), uint256(0x0f61e25c7e3cb5642d00a1d526417d06bbf7888f323096fb3d81684c992d4496));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2cf4514311aacfc7185f5c2e5312e1e7e407dba02671939888b3632cfab8c01c), uint256(0x1d0af21f81ef5ebe4a261c3a488469fc022e0b7f4312f1a0897c3a0a9b7b4e90));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x244e530d5455d5d379cf0069d83e2f3c1127d84a260526391a480554edc682cd), uint256(0x0fa427ab329ae6f493943a7ad5ed1ccc65a1bdaa353d18e36e1e8a74c418b9bd));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x1a6911bfeb4c27215c5371a2ebe17101941463ec5581d7fec007306575fbc99b), uint256(0x139e976e7d36786097aa64a949fdc961f6f7157cb115ee262b0b85112a27b125));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x01d0b4a6bedb99ab27770f9c6a222f43c9ab7d847b40d424d8ff811ed119176c), uint256(0x1aaeafed9d6c898e7f42dc3e8bc2f293c386c05d34c5f2925f60edb2c9a0aaa7));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x09e260bb7b623165072ef75506c064943ffabf72c1e21539daee65165f64ab97), uint256(0x1f2b32662a8ead90395df372191cb2eac53021bad1cf9fa3c9d6bdd21a187c0c));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x2aee31edb4e00abbf5ec3de633457850f18bd8803f89742be0c1233d646e692f), uint256(0x24e458f2a1c2b558b1fee96e0d8e395d61755c008d7591194442c5272986459e));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x245ea01b3d4d8e6f3a15340ce0a23f7dda9361a3420e7d05d6e82fc7e813113c), uint256(0x0d83e7ba13948c4a2865628de0e7de79e73893fe097edc97e02fa85d86752f11));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x2db92ac6a417666f8fdec81739c48855fb5522d0ec3526377628ad4913797f92), uint256(0x172948bd9489f507cf7ef6fb1a29cb72929db098c34a95978bce082c1e526c01));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x22982eca9a06069d361562e020b85c608c16ed5cf9393a07003193f6dc5055e1), uint256(0x03bd12e4d262cf5fdda3995de84876d22944ea0b5484624881be1922dd0df789));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x2219d07aa12c87cc288757ca5cfceaf1a0323bc8ecc0f15c6ad1a5b67d762182), uint256(0x1ebacaad61b697a5d613441417378ff91512c35469f007605d3f4a46e55f16b9));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x05bfb8b48bac361795044059b60b7e22785917169d5d036fdc90c218cef6458a), uint256(0x0a62ae351a270b2cabbbbea420b3e46e689ef0082ff9051533f1d59b9e89cef2));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x2a0f648402988184c544aacc4e8d88efed1639380341ee80356afcde66072269), uint256(0x08294097ac2d65f5a41ce2e2f584c67b30708af42d5e24ac7ba1d835ada4be05));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x1dea95530c0647e8e081898552a9388063128503151dcb87ed94d1c5e3ca5556), uint256(0x1180b4d4cb00d48aec2114bceb0e8cb6c76346cf37d555becd42e20a81f3224a));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x0296176020c8ddbb4eca4f38d0d018792a6508c1c32fb0c9ca9b776702bc025c), uint256(0x2a2ae1f5de2166f996005fa42b1da2cd3164914dd0d2293f815b05b5fd2f80a7));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x1a04b06a9fcb333407cc49eb39d97eaa45763101303b0b9467dc0e38ceb1029f), uint256(0x25159feacee796bc5270c66efed744e42cc647fd63538b4851c4b3755e0ebd75));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x0ad7a5f22210a6f288a669fd5a42683f40c2d241f7b92f3905f7b3373e33fb16), uint256(0x0bd9a0c0d8b9203a11938f3c4b370fa22a4fb48e40b13002254d5c58e278886d));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x2edaba4b90ad3929e9ffb728e388172d92fab075087d9bdd31dff6021e293b1a), uint256(0x2501b2238e8999250612451a1ae93979c41c3127415bddc92a5b816f819e705d));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x1c2e9908dadfeafe7c90de6340cd65318ddeb15375b099b7984cc218b76f4355), uint256(0x2b7b1fc206a75f2bce9f0ae0b41e4031f4191ecacfb24108c08d35fa192b623d));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x0520066aaf41a1ac7e7bee74bd01d18e6a3c2ad75c7a57c0bf0ed31b33ac07c5), uint256(0x08117a9c62c7b93f0f1746ed8f6ee5ca661828ced7d28e6744b5bfdd37825288));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x0f9dbd5e733d084f7b2b198e461b6c28a486c3dcc341076326fb371a2ff4264a), uint256(0x30115dd5ccd4be947e7250941710956ccf2072b6f748ced3458d071bdfdb7442));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x0f823b9b20f08ee49e8ad05221858d424d9fdef864a9a05a258891287e1880b3), uint256(0x00a1610a793ada3a7a135fefa510060b7b4e402ce26a23fdde27a2973e2fcefa));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x0507f34280834b236961296efc6d75510482c70f5dfd47e23107176cfd9b38f9), uint256(0x1f6c770b3c158ea593239ecc5029aa56d97e38e35618be16e4bc9b9c4b9fbb28));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x06cdfbd7b99c5b71e42c60ee4ae36b71715bfc695ff4c95142843a658a432477), uint256(0x100f945deeaa287ef776f2e96f7904f2568b99d00bb2f9f676f43db1c0e0faaa));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x074a95395a800dddfbadc94f42f0a63b9f041f4f05ffcd1f23427d3758949109), uint256(0x209d00517b1e97de815bb5619c1e3540cba457642abefb2f730708dc8a0ace02));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x19e0b3df57ddbb354dba0a1aa882ddad68c9c1c611d81572e3f69bf79494ab46), uint256(0x13bf2c7fbad68e312496163970ff3c1576bba256f745280273c93cce9905a5b2));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x2bfddfc22f5dce79720c291bce6621f0490157ebabd4184524d9c5dffab7b3fe), uint256(0x0776d9e784921b00747466068d9d1aa3961a1b2febe5a9e5a7dea8fad10fb203));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x0ed567e0d4a9337ff98d4e19494335ca3b44ebddcc2d9032499e7c10ab3d1032), uint256(0x1b7a49b1d18a4958ff08f317aceee57cbaa86f7900bb772a220d3ac772b7bc17));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x02ab73af28e5c30796b4c358680487c25200fe455351aab64905af5f7f9f9883), uint256(0x1c747b668b304bdb7ccb609184873b0f900b23e2f52d6628c8a916f5118ac769));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x1e51b9a705bb1b1eb521db550978cd31f6f7b06ec87d2cd1f601d38020cdfc24), uint256(0x23a938946c1d22df117cbca4e7937bac8873df82116a49efd3c9fd73982f3642));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x200d8b05807f90209b01f31158b04aec8694809eb2b39f5a5a0fc89b48958bdd), uint256(0x1ec52b2248b3b28a1a9bd4389b0ceb454c2959103e0bf677acd605a3148e86f4));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x2cbf5e7fbc67bbc59cb58dba133a341faa7ec90ac7a5a5340f48dba85959546d), uint256(0x2792b431d8a58bb4260ed1fa773c804e46372f08d03269bd13a56dd24acbf2c2));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x260b85c8497bf3a805be7db1a32ba37553475e50a294211848dae48fd2c0c398), uint256(0x21523743a24ce7ed2bab108a3e4342b05725830120d9d2178850b34ffa85fa85));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x282276656c23c505f2df9251b15e882d74454edc201a5286d428163afec3bd9e), uint256(0x2009e00c08d332ca50b9e221e283cb67f1bd02db5706c499063f486c50633024));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x1acfaff916ef63d188dbae56ee391e4a9fba131c8fa2819e4d790297b0f9977c), uint256(0x2de5376b3ff870b482daed642e17b56714d79923dc2338fb9e749d64ae245927));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x0b247fc5eed14c1041aaf97c263c14c688f637437ee615974a3c5038a51160ba), uint256(0x0a20f91dc21a5faed97131fb880af6ec6e35660bbb26687af01dac9119fc8575));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x0360a8e763fc0d6ead1f371316618924a9a69a69175efa90fb07f97e8c15a4c0), uint256(0x2435f9ba9d82f233c9e2f11974311e0841dd28d007563c847d57d7ce8c200f16));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x2a6ba11b50edbf811c8178775c955ed19ef9c576a74977eb19eebbd55b470f01), uint256(0x0f6f2a0f2db6f1dedd3ef4c7b8a3c318739d86da3c4dad4b0b78056f56fa8a19));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x0c125b7f2868499325da7f25f378cc98699461f46b65d249a720943c7f209422), uint256(0x0a82acaa88a21a10744433d166731520ff0869cd6ff8e74daa70949382d9cd76));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x256d2d6a5f9b8469029b1fc5a1b203ffdf0180314e1cc7c5b0c9d1a0e4519497), uint256(0x176b0322c05000a643f5695849897045a96942373a21d6daa0b1059af49e1280));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x2999a1434f84bc206a85e8fa3698709e877f3ce68045342ff59ca5cea94fd56c), uint256(0x167a023b0671ee9ebf3f6e4437f88a5470955a021b2b80f950b09bdcdff335ed));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x1051c8baacbe62c044bfcb26269b73cfa6d8388847b4f1697f6f6572d50560a1), uint256(0x28bc88e81e7b0515f418966f2e841827304923dbf070b8366d30ac8ed9042185));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x0aac3cfce43496c4c41d9b14e5386b5f81abca4b7ca33cc690bfc31e633d167b), uint256(0x161cad996e4659822bf5d3a2d0ff16fe000dce558b5765619f81040cf054813d));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x06e0d69ca285fab871a169ea9d48acccbd3fa5cd12e102d41fc998f9f9a2b3e1), uint256(0x09d5f1f5be62d19a0ab38fc4aae26be8ffe7bec69b5bfe8b339febc83d6c1002));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x1e75dfe52ed555100b8e618634f130be2b9794d1d6ee746ea91d7abdc0963e8b), uint256(0x1fa21d59f1e85da09df398d3858eb3da4b360c7d040d9a50b2d0ba3548db77b5));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x1966a3ef8137cb342945ebf0777020e7dac321e1dfa3f4c343d2ae2bad466b6c), uint256(0x108250a503d3952b2d01b2251be82eaddb4f568211866dbbb785b8ccbf75a4ed));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x24d89cf270d1f51adb0edc803cd6110a50e226638b136836e8cb434029d7d00f), uint256(0x00bab971c469c71270072aa8014c5d208890787ff1c8a562b2225a1e09f10272));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x0a12369061a77a23d7fa7548082dfaf534f430df1366581b59ee0bcc303c0196), uint256(0x1d8934bd621e424b6f33b21c21d9cfc372110c8f25087d76d8bafd1e22e956e8));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x1d0cd33514b7df6ac9f0255d77531a3048d3d2220b4da6b531102a69934cc5a0), uint256(0x2ec0ac60507708e751703ff3d8c07ef0b073e466fa3f6d7402894cea5b505979));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x2b5abb67d59b5b1560f55ecb3aff86b594b6ae89ba3047564577db212962a6ec), uint256(0x0051eee38ce096707255331ca06eb63ff3caf0a9d98d490f1c3ce08e46801643));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x1ec765394b992e47a55bbfaee3ba148af9b8142a1aacb218e5cb4b152649ec90), uint256(0x0cdb8e135367d162b1c2ca4d005ec9d0c0964dfa0ff80386b20487289c6dbbbd));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x0c18df141dd7a17fb90bbe66b48c2f44ee996d1479805c942d21884ff982379e), uint256(0x0aeacc1534addbe9f21d940b5d3712e958b37160d5cb770f939cd21902beb547));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x14ec2bf580374c2a01c867c64172ec4d68f913b6cdc3d4829d018ddda06e1a71), uint256(0x1a3a27fb0c8b1907616caa7fb6e04f88f006f3c13c4dec3708a127890dec4d45));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x1268cfff7ba6c62fc6b3b404cf812cabe13c1e0915638e92d3da8714ee122d43), uint256(0x28edba01d117be945bf016f96c8dba2443c64d9337339795cfec9746f4776a2e));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x2f9c4dd367b8df11149cd9f7b753550626b6a9e8d9c3576aab568dd749fb41cc), uint256(0x0c256f9b31e762d7de1c94a3b52898fd186dc2e861295c7c57ab1daa58fcb325));
    }
    function verify(uint[] memory input, Proof memory proof) internal returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.a), vk.b)) return 1;
        return 0;
    }
    event Verified(string s);
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[68] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}
