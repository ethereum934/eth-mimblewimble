// This file is LGPL3 Licensed

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

pragma solidity ^0.5.0;
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

contract ZkRollUp128 {
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
        vk.a = Pairing.G1Point(uint256(0x066ea872c111a8ff12f255bd47270df4ebbc8b6960832e41f03c5def657c90e2), uint256(0x0aa5edd08db07f92a6c7d89aba73356e69922d30f7e548af72c29b1788ffc579));
        vk.b = Pairing.G2Point([uint256(0x16daf7ce85eb0109a58d4de057388567153dd01d4992741674fa0bc9985d086d), uint256(0x00c9b025c83a376ba615f6658571d5ffa561f68c9182306b032ebbd60731fa84)], [uint256(0x046580267dec3ef3b8fa5294eeb88d62447814434feba342126093e32e8fc0d6), uint256(0x02621155410178a378a4f46ae22ae54b2133a00ec970ea69e142954f15842321)]);
        vk.gamma = Pairing.G2Point([uint256(0x016e181489c1ee30c2ec834d748809aadf4fe332ef78d2458da38e3455508b77), uint256(0x2e95e40241122fc538ef00d0bc2042b41181f1a02f079b9a6fe4560c0f152d31)], [uint256(0x2f3d5ee37b516c9da749ecb8ce8fc277d3278066a273c54ca349254722f20082), uint256(0x2b329d3e2d1025a361944f904b65b09f5a220e9b6db0a80e58cfe348a874c507)]);
        vk.delta = Pairing.G2Point([uint256(0x2aaf6e5b651cdc22125b6173da22304712f025b1d153a2799b68bf7e00eab6be), uint256(0x02f6bd2c4ecae901b67c49bec9acd6eeae2f6ef5b7eb4934e69bbb0e2c183e6d)], [uint256(0x11ef97c9757857b1b99d4ab8d9a346925983139fbe3a860bf56cfcc07f1f91f3), uint256(0x1477543d2e71260bb187b4d51bda28db2c4b95092c08b94bb7205a22cc1366a3)]);
        vk.gamma_abc = new Pairing.G1Point[](261);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0e3911c3d343602d68dd320b5a96498453857d4dca98e31b65a6a9ecca027cee), uint256(0x1ae5635692062dc8f8dd36301a47d979ec3f812f89155d3ad264085ad84dd28a));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x071b75a4a0575f7f4ddefe663b7f221b548aa59e3abf97ab2146a8ccbc9f92af), uint256(0x2fb75176c91ad2008c597d954b8fe503ea835ce9df42faa475d097005eb7d1ae));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x1a1249b64cd2cf712ceaf5caa9f8d7e3f3e0484909fa4f74f4e89dd07aee7c07), uint256(0x12dc3b156557fd268788e75aacf29940a41b789c1869ade6876f7e9a1e02937b));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x11068269735824b53ad72bf2428153fcab7daac0f97ceffc1f7d247d4993a9cc), uint256(0x03275582c060a7aac5207c3c590bd15d3f67d787e4c53b6497fa0b503fc06b1a));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x03f237b839558b630ec28d42db955b979daa26bbe7473a01923ee51c231a55d8), uint256(0x16df53037da0dbb47f1d0813cde83e7fa2b58e440767e70eff48dbed0c8cca02));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x08aa0dc48ec9fbc5ab375cded3135e24fa256ad8e7812dd0704d0645c8cb18e8), uint256(0x2c1bbe412241fd7496036f74295f3efcab8d90171845895e3d4a2b17903092a4));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1aeb098e680218a2d616c656de2f4cac8edcbb7ca661161380d57e5e27c7d4de), uint256(0x1fd1a77b0fa074a558231c7d875a9daf3c3f090203f8c70e0b9b3bbb246b1448));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x061199b2b9713dfa1ca3cbd07238868042ca3a6f7dc78693cd1fd7fe457a98cc), uint256(0x15befa031744600eb3aa27bc46ad29358f1a2184c2d6a7404a60d2a1927de65f));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1931ed37e60cffc5343473a35474f3975a215ae51787cc075b85f051361e660d), uint256(0x19776dd72084200f1ac7325bd2452a3beff2ce6d822311989ccc44028ed31307));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x108a3b10755bf5ac6e2d76cc1fc3a4ba6083f3356638881f910ebc976e68d592), uint256(0x0b6158a2fafacfd8cad10d71ba32acee857c65469180084bdd55fac1cd35b739));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0fb8f75610e200a24873a86b73fb09ccab25d97c49ec117fd17cb6b3f7e14ba5), uint256(0x0dcf7b209453cad26723569299a3db6257aecdd9b1a27e9c888a73da2c90d822));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2f1fc44dcdf3b1b4e2c17a17b4dbf397a150d93517341a55624971d7c2be6523), uint256(0x1ec8c658d1d29565006c054b85259763c5773cec3c757bb4fb8eb787497f6675));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x098a4570f04034ac959ae272c6bac433c206333c70022cb2cea9e94d037c7dae), uint256(0x270d72240eb677a8f22e317c5ca92bd18bc3baea2848f98d9ac6d5433d9f7a82));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x251aba01447f6ef915458a857bd96d38a7da7096a43473c4a1a0bdd4d11183ed), uint256(0x253efc42e76152696ecb316f4945c76d4ece7a567d3b2e0600ea9daa88af029e));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1d89b68680512ed82eb4375720f2ad72403935048e4fb9cac826cbc82bad1471), uint256(0x202af5ad2f7d78b49fd0ac7b080c929659750af58e0a4ed14b3182c82a0775db));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2a5fe03da2d6d91b99cc218367fe828a96791215cdc7d5791dbe6b61c7f8b198), uint256(0x2381832a67ae2ade2a0e5967c9c96b13765868e4c8c5f460926791002cd5e9b1));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x2dc6f218eb4b6bc3fe2f98e20339d3e1f206ea17fbc6eb41f24215844ccfdac0), uint256(0x146de11a14501defa4292828f86135a169e34f1b35e08f965caad5296c59cf8b));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x08d944fa22ec49422b61b651f23c253a9d0aaa54eadf765ab59ee11ea029a1d1), uint256(0x06fa1391fa9ce044f1885150e26b88b853c94ce073dc926724e128dc95b734e0));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x17ac9d78b2b07d030c001e27d021d234151322b1c0f2e126888c224368fcd26e), uint256(0x1a12c32781c78fd277f3a550506e5b44d94fe6d454ac72668e3db7592e18dfde));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x10fae056a89c44dee0d4a6d02fd377f7d02f93296558c2f0fe048477b4df6946), uint256(0x211d543fcf9f5a4d1313d3d4d3f31814c96206dceeafb2e2c398c9f0c1cb7398));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x2ead32c7a5f31fa35d0b891ebbadc846aa7495ee09c598a1cce55788db8b0d63), uint256(0x2a2444da8813af6b8e58496cf042121841934628043e9333ff723673f591db25));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x0bf9b0c9493b2318942b89198fd8edefb7b839e09c3b09fe3e72afb8c5fba9c7), uint256(0x0ff444976d9075b0fd993ab2ae0270f792e4559e2a7dae0bf797aa1c489f289f));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x3026d133ae237c7ace9783874bc9caf0349e29eb3cd1551b8a089f3eaa5c8d37), uint256(0x0fc9c367a346a8507fb2ed080426762ea247e73d9bee9654af06a15423f36d61));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x0e3a39fc6e64739ff302fa35840a605bf246a71dfb9c0c9acf900ae04484b755), uint256(0x13030fb69bf846da54a5782239ae856aae2164b755ae05e1b6696680f59cdbe5));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x15d2d57f9af3a390449a41df293f50c9564efa61bca48fdfbecc250c42063996), uint256(0x1d1cc935108137c2b9acc849bc2b4de86d03daf0517af5dca2472d44d3d9c5b5));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1fc14d843894999452cbb3d82ebe27cd23bb405d5bed450478076ecb37314085), uint256(0x10c51ceafcbf98713c7249b63ff15d07c3b796e4d571d52ee4f2389bd214be2b));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x0cb556e6f6f8b5552646efcf404d967d569f5681c2b2b5834e32d6fad304e387), uint256(0x24457e7da194abd712bd0d7a3cfd28d7b1948930118b0e2012b89072f74683fc));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x088807fa51bd8f959fb62b6609be1c654993ff881817c7bc53b0e341afd603c8), uint256(0x15b33b65c49f776572d39da1a8d4fc2e82b3d6642e376ccc487cda1354cceb0d));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x0bc33fbae3dd45cb1ea3ba5f221714d59424699a344d38c14f02c3fc6f136e41), uint256(0x01dc06a5323b39df7a1b9d902c56c3a19eccfd311eba1667b399de8e7a1efd13));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x0aef888c2546a76f9ce1a532e9cba0929ea6a565b5fc3f6b95e624929beb8239), uint256(0x0a26d2d5834db6733d653f021221d3cf1432c83b687a26ca8a9e41bc6538aa85));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x08f69055ba04dd973df9f946bd442d6d9d2987eb6bd890c21cc43c12f10d7135), uint256(0x0e44f6251ce6e5f323cf2d41b5b654db1cdc10e6d26d8635dd20089060c54319));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x08915dc7a92e3086a383a5a56ccbe906b6db1eeacb1802a7acd50da57d4d7dd8), uint256(0x25961ac7bcc90628fcc4ad3e48c908a9064603a441c2126a43b6207d74ac4937));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x0754e810a4cbe2fd27b9b9afc71948c4af2004cf9d600492765cc7f95b47b468), uint256(0x22e46bbf4dca103dec7f349914224f94afe044d1294cc44389268bc996d719db));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x1b70e61a1c1c473494f016ff17347e0a539d3b461620fe2a518c53f4e2cb7e7d), uint256(0x0c3378ce232f2c9757666b5ab1efe077426f0a42ebac61f53033f0b46a8e11d9));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x24abe3ef4f4a66d1586eab3e1aa06c83b7561aba7db16f609420069dc5ce19ef), uint256(0x0792544c2fb24b30ea95e0c31a93dad80cb8fabee741774c74dfcc9c483df70c));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x18970c19e022e3ecf59eb254238ed65c4c48a81e650af929e64899d3b9d1f6bc), uint256(0x1646cb73c7d8e9bbeb0fea1ac729a96c35bac9308974efff537207101bb3e9a3));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x12210e76a459dd8356e75cee6b13240fb54ac2d534b8deb8573f36a1c34ea8ce), uint256(0x16e1d80ade0130c786c6c86c980a38059adf48f49719a8dd1a87c38d433cf2b7));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x114004d0032512ab3b39b294c5b1e6449c4e541f5797b3ff61a685bfde6541fc), uint256(0x08db90a7d25cbebcc4739d1bc77aadae407a29853f1fae123a7eae50784740de));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x21facc5e76c0b0883c3ed07e23178fbd5f6825b735d2d45ab8d5d8baddd703ac), uint256(0x0da3862d804bdbbbfe3bb3da32534ffa764e3c47066bf9a6d7e439287aac484f));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x2adf09fa066d46cb6350d72b43701176dd4265978d343c868e0feed79335b13a), uint256(0x2dccf6604e9ecd3e184a06249fb53f64c32aa6dce17738d4905268b5e8063d0f));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x06d8489b1a43dc050fb6614750ea9251dca25e3f2f9c185e89c0fda383cac292), uint256(0x1dc7e0142269aa10ba16a5f651d3e7c0cbd5cbf6ce694e18e7f6424716aa67ed));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x136b85e281db226ee7646c6193784815182a44ac9ee1ca9f4b279ac87239b146), uint256(0x03694c1463953798af83792645ab5257ed999ee4dceb94e45e77f551aba930ea));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x20e2268e0f6473bb9e5ec3140fa83085bbf7af7b91b2a43ae498c4a114f2c2a9), uint256(0x121875413bcbcfa3e7479d5e7a61e0763cf80f4bd0c11536d1763d2725a5f972));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x2b43b5913814ff478a1bb30c716024fcb0e473e45549181ed7fb72490752cbab), uint256(0x0656979081ce18415b05b1e89e7c549f76d8febfe74ab98fe2e9d1c47ec202ec));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x2f5b80d6bafcd303a2b3368b211e0045d97448fa87d0690952507bfd26c666d8), uint256(0x10d06efd0000cd8fc639bad3e3e5a89c28f57574a7cb267795be4b1089d2a6e1));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x17815d946c0d5054b5009f8f81fac6ffbd62afd3f24a22d16c48fd846095fb09), uint256(0x07349ff327781431f2b3e6dabb77bb30473bfd5cb4052552959074d906a4f28b));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x279c1ab8d203d26bacfbc7e9d09adaa7218ef3a11dd0a0689559464d72f7d9d8), uint256(0x0a87054d364c0301c46f230f649866c784ed4ed006a6b9c3de4a8fc650326a0d));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x0b3cf2722c730e0e7f99ccede547e310358d3c3b93f97992e0f7edf62e1648b1), uint256(0x0c742b7879d2cff40fff5b992a39e8a61e7aaac1ec949d481f381d2047ee56cc));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x13a90270e3ba84e83d1914c96cba418acef9c698639047b06d26f71e0965ecb9), uint256(0x225606cb6f84aea0f374107dc96851d8a4502cc24ef12f954f83e328d94a4f16));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x2f2a8a32573ba90d7374c68ccde768bf7fd26d6895d6025b9b0641de2a769c8f), uint256(0x05118b36e463a17e4720d8d6d9a6ee288e24ca81c2865d83ba2ba0ad66f2cded));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x2a03c72cfc09973e752474506539ac613ebc9d7244beee3aab9167393553bc5b), uint256(0x140cc54c8dc146b71ddc9c74167dec95bb5179721eee54f8c87d032ed7352280));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x0d1cef77bba77d8775c0dc07ed3ea4c0ded293f444bab0a6c5ec02bcec96e3a6), uint256(0x15a5066a942ff76a2f4d2e4d3a1117974a5237994d920d303ad56d49ed4a93da));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x207c0efba0c5b03ee47657346d4b409cdb6bcc57e3a16e06e461a32e3351fc50), uint256(0x213b1d15d0bc73cb61c09319553ea87568cd22aac6ad5f82aac517f3069e28ca));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x0c3ddc70a7fd1c5205435fa925f1e5b668a539234440732b12887b38f6267178), uint256(0x2be305584bd7e849e4f448a98f60d01205ec94fe84e4a687283e897bc70f79b5));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x0f0be45ed0ccdd07bde24d30212d82a5702aef6523552573be08f1d0c053fc83), uint256(0x2e3a36e72cd45a8574dc036b7cbba816cf5e016dbf2e29f4c14a4793faab2403));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x2facc2f61d916f469cf73ead212ad85bd5b04666dd088f09ebd225abc4ab4ce9), uint256(0x29acaead10eecfc4dcdf4b56445561f139be605484d53903617de2446d685aa3));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x0d9b167cd06dc45b7e7d978862961e609bd18c4d12c89c05685a6a19fb3622dc), uint256(0x1be31cce4820d0281807dc818ffc2dcce7cbce4000e322edd41e0571a0c99f3d));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x1704b6606884e15e8554cfd9d632a9389f5919708909a20f2404b66e4123d270), uint256(0x2cecec6f30136369478fcdfe313eda65fac168921d83f37e2bf370df2537c419));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x2ce55e4f77a17886a641a3e17ccfdfd9d34bdeabb3ef2dcbc88e0c3a0dc61b29), uint256(0x147bc6d32eefb55bb1e6ea8ac154e1e0c6527da47df90ac11b44bc46b9266142));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x17b265d95e7816af51ae1638bd7a21ac450b6ee2c692b8a650554d6461dd580a), uint256(0x047d68309843b174ceb4081cafc24a5e999ca8f6f64daa4f349ba7488cdf14e9));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x230767cf48bc4aa5f30610a02f16b824426abf8e2b95691903626a35ecdd98bd), uint256(0x00dfcd5e139965a7b8ec69049959519952ff0b0e59e4288412b5b4b4ae0f9b4f));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x2f5fe88df7d89b5d072f027f528cbaa45fb2d5844e2bc7e68479ef4abd4b1689), uint256(0x0acb108eaafe356ba545f38f715e3f96cacfb342bc6fbf0b810d70fb07919243));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x007d5106e375289ed5f513fc73d72917d6fcda1c946f71cc5718e5c2534f3ab8), uint256(0x2835a28fb426f124f0662fa4fc9e46ab246fc68ea8118982c0e27e4c69c47384));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x01dc9147bbeba7f47f2ac028906fd276b77722bdde93eb23057dc2659c281c56), uint256(0x2beb3a7279c5496930fd550dd2da7a0846fe3f4afeb3444374daee30fa29a63f));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x1f7389276447b9dfd2f2659b457f4fa390fe8e331994f74f8c768ff1989846df), uint256(0x03771ff2d05301d5f7fc07055fe1c6fe4838cd159fe7dab9a579cc793123634c));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x21c9f9e8b8fe0e106539029f3a6d40ed6c796c3bff58a4b1b2518814f5e87f87), uint256(0x09be54d5db36c016f7ae4171349441529a90807043ac36a1757b87a6479732bc));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x1c4bf66083cfa2b636bf1342c12196ef004714d766eb12d56c1c06fd30f8ce39), uint256(0x1a1ec04dacf9fa9f6325e391b98bca32855467f25f6d983d160b9322dca60973));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x28bcbddf809f4155868340d852f5d4e97d3bc5f0af86b6eb7b258ae4dc449ce0), uint256(0x2908d322b6dffae0139181c47b96ff37cb29c4cb07e59dc71b50aca5ac0363ee));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x05c428e701d72dea44543879e7a0519042c26b8dd9fa600433b18dcfe916df50), uint256(0x1660ac6abe5a22ddef9d74304900cc20e2aae0e1ac038b20160b2b62d1fa9238));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x3002a078ab877477ec0b61783a706d7829ca6c45c6619a35a0dcbfa9b9313214), uint256(0x2a4a91ed762a7a9d4934a263449b5ea7acff6fab55e122cf89f2e4a48641f884));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x15bd2b844435d0f561dd6a07042a68d1e9777e30d5705ffebaec0ad0e6525423), uint256(0x07407ae4e2abeb7d7113004907806dfebb8089f8ba61947b6b39804d18e62f92));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x0970b55ab8500e0defee5c97321619aeba7ed7049012e3cffd504d264fe553c6), uint256(0x19d7109b40945fedd63c25239822d54d5046769bcc2ef69644fda5b66fe2564f));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x18d45e005b51728ee05be69609ea85c7f239718f9783eda685d5329ca85a09e6), uint256(0x2db61585d49820eb13ed6bd741b6711bc6dc4c1ad59a51c48a120d20c20ab0f8));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x0a7b4b9c657c541152ef1ba36dad0324a1be4e8a5a821ec03e6ebfb84ea63656), uint256(0x239ef43c3d4ce8045d0a996c27bbcde2eb38d508651a55c8f623fcc26ae8802a));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x136695a739446de4c942c9568b5347e43abab6bf73a712d1c2152303ccfb3b3f), uint256(0x15456debddeb58a11f655719b810dc512fdc734f32e209beb88e114e863a90b9));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x103945ccc96e9f13f480722d8ae28d56a5d28784db09fc616e9da8ad0cb7756e), uint256(0x0d4610583b47aa8455f475cd7b01ffcf0bf0439d381d6194dd89ee8226829dff));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x08525ec22716c568ba3b783df5a9903d3e7e31490231adca8cadee524604afeb), uint256(0x1ea5e4539ab9712e0f1d74a88da53d72a93c1362ec2388610051eb70cd563138));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x02cfa59b5b463f9219a4705482fa34e36e1401f2870fafd9b9654827e79342cf), uint256(0x0a0a055d898a0cd9f58f00c9bca46070c83a0a12611f044b9e2980235e83b259));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x1b164f41a50da2b4e900b3f0c375bdd5c0380fd43bddaa7e83c2231046720760), uint256(0x2d214bcac0df2da9d36e7d5048e4db0c660b2d65a1c9a6777cfae14312dbc2a1));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x0a463e80afbd3be34cfe71a0f339ef7a2c3036b2bf1f9cf512a4f8095093e3e1), uint256(0x042d16072c81cd4f450a2006b6b168206b65b1460e1dc326aada1a3c6b3276ec));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x216bb4b800f8f992adcfe4f03d5536126c56426c0f42be2f35c2de7d1b21782e), uint256(0x13fcc89e7676a8018bab2c807f906a1ee81a085385764b5e86d883bdfbe17a72));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x19faa5b390821cf7928edfe0a57e23f83ff9dac25d4102a9dd894c5664c36846), uint256(0x1e756782f9f6e5d73281334dee6f10f29e42c464ee0ef6251b86c6ebfbe1310d));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x048af9c19befd9df7c95db049694e77e42f263dafcf0c8ef610d6f20514c0755), uint256(0x2427f3d1faf5872dac3748cd06a50cf516b5400cbcd13d68a101b13a2f546a75));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x23711648d9d034ebd15bc2fccee14a2e71735123939d1e4327d97f9826f9c736), uint256(0x17cf3ced9072aefc46b00aa758bbea9e343b9da425861e7c827cc740e5b9ca8e));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x0cfa4a30472cb5aaa01cc986c59ac7387fb229bf937ffa7e4cdb1fcdb85ccff4), uint256(0x2091bb1c0aeee7f6ff1d364e47239d0c2d51d0a552178572863a4cefbc74cb89));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x154599fee9fbef5d212b79e799614ce221dd3b9de31d8d9289b59a0bbffec524), uint256(0x101ff956b6289732242803a6e5259612a13bd1a0819b66286c0d151a1cca72c9));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x06e326425bc4187f14904064661c54fca56052d9339420bde53702afbd5f79d9), uint256(0x0b41f19f034e30e45259b0ec65ce3127f2d771f0c86fb5715b595e814bf50b42));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x00cdb8e397f53977b5117c060157de8ce9ef571e8e8f23e765a3d1d8c57b7e1d), uint256(0x27ec192df6e801b815a24a0e579f619caa518750942e05c234d6a917240e62f5));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x0c5bcb6f73a17d0240405457bfccc1a599a0fe2e111eecadde995beb1edeb80c), uint256(0x263bab028cca32990184300b8757d26a85f809b995ea5869a9719e8cd29169c3));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x2c64d818f4a1c4140ac0c361cbc8f344abed407f839786fdca9b25f9af1c676d), uint256(0x0326f3913cfb968c29fb69951ff780f84e9f0216cec0be4f9a5f8b473b40af03));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x1d7f2cd142fb108315301c099c450eeeb75d87d467da4210220beeba0ce19302), uint256(0x2ed7ed291674ae51d223074910434d7e9bcce94c313705d31844370e505417e0));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x303102ffe1b18138133911a8979edc8ced5d3f349c5f8cb8abe8ce8d68b18755), uint256(0x13b534924d01450f074afcec8b7e2f0ba68ba0a89a84c693df1c85a9b3e139c1));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x01c72a211e36a804868fe4ab2e1af65ad64456e3f81be5bc431e01060f0a6349), uint256(0x239b9674a80ba0b743107b288d2b8eddfd8d0dc64a9f259cd9ed580d4f5e11b3));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x20bdd1907df0f710bdf5206af64f0b0f29f3cba32710c5607998a9e553a4545c), uint256(0x299cae6f5275faa6b67f54742c04de884f629d6fe91b17313276568276a82694));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x06d83570c4860ca5a3d7730e3fe5a964c43c1d6b76f89b274c4c52dff1c57a09), uint256(0x0179bdd7c9fda7b7e65723458089d9c5e61b26b807d1ce6253c38bc40ec9d6ef));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x25c878f05bbb84aa08f6d0c10d8f2b8ae56bd357b7627c1075e33d3f377a67e8), uint256(0x0dd8c8267b6f45e6f548d074134c50c6b50cf52dd22a7f27d7df85d973a3cd6f));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x00ff4bce3df9792cec2a472eb95dd90f7396e9e50b9fa5c2d45dcf5acc204e11), uint256(0x2fd7bcec9c8bb9136fb174c272620af65f5dd1c277caa7f9c9efa8f946120b68));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x2913834b9be3a9dcf76b74e6cb32526848219382b29e9e75b9fdb0b35b39379c), uint256(0x2874721201893e654493981f44927b48a02fe53251f805d60108eafe75c9db08));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x09911b9d7245f2f601b681d2dc9d11650a0342cf463216303122f676d6a512e7), uint256(0x21e8500741d4442d262bf0a4233d9f748c6274f8aa39bb078f47edc0a275d5f5));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x1a878b1ce606d7774ca6fad04e42fa06300620ff29c55f588d0a53ff5d16cd6b), uint256(0x28aebdb02e4858e337e6334b57b01204a385d3c3edfa6cb4d9700e92adb1a4ec));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x15b387659e09271fd27c6949e838c7811ebffbcea626c2c69ea372347be69943), uint256(0x1c76658d2347dc1ad5fe4c7a8357792cc4c076e848580595c158dd6f2aa4009e));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x19d66c0bdefc666bf25327a8f2d9c8f005abfa1b4fe2a4393a3243ce87ed2f86), uint256(0x23253e586fe3984533f5a67fcba59a1bead8b7361bf8f525e3fd0d3aa11a0dd8));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x2351a92e0a8f072c89a02c42ed86655f4faf88259ed025624d07f428a4d952f5), uint256(0x2023e0487964d015f732cb3d135589b96a961bf12b8fdd544b41d5d3c902025d));
        vk.gamma_abc[103] = Pairing.G1Point(uint256(0x23413a60111d17c84b404aa39ab0175d9c0aa302947393eef5289616819445a0), uint256(0x00ef500d87856e9eb7d9d3bcfa944ccfbe0c9ba9e326bf2d6a24aa63644a59b6));
        vk.gamma_abc[104] = Pairing.G1Point(uint256(0x1ff32834f845912e44fde2b2e478e46a78a9b8491d151c120e110645e4133bdf), uint256(0x2ff6732e0ddf9bded456fc2edc01fa9a1ecc1a15cb2556ba9755f90cbdd55c6d));
        vk.gamma_abc[105] = Pairing.G1Point(uint256(0x0f1b8bbac14fdd4957a2406d9b8c3d050cfb9073bdf16f8b8e0a15886b138f24), uint256(0x24eb8900e6de4cbb06bac2199fa8321f3b3ea121e3939f733f2a79687b2e8915));
        vk.gamma_abc[106] = Pairing.G1Point(uint256(0x2ed37e204e643a4e3fbb633c663eec04404ca2d4b9156a7d116cd0ad131b9102), uint256(0x06b9c2e5cc658e8602968adca3598f72a1310e5b2be02cedf5c2e65842196fed));
        vk.gamma_abc[107] = Pairing.G1Point(uint256(0x01e740a3092edb46b0d1f31b00f5e38a0f42a709c8abef10ee100352a9f25fdc), uint256(0x249e9c7abe25f713dfb302b7fa011d43c093c711723a07c86b13578f13e30f06));
        vk.gamma_abc[108] = Pairing.G1Point(uint256(0x135d6b1eaaf1f9af52e52b2e5d62fc2f10bb684d73c4e6082616b6e11e1cda4a), uint256(0x2b0911402f2770dd4db0e4bcc447528da962d9cb52d0c9c38ee886b860171371));
        vk.gamma_abc[109] = Pairing.G1Point(uint256(0x1bd0567594d2cd8989aa728b90ae7dde744454272863f43b419be79546642d9d), uint256(0x27c21cdd7b08f188dd1f76bbd709b163f00fd99203488cb03b8728abfd185031));
        vk.gamma_abc[110] = Pairing.G1Point(uint256(0x0eb15d94bc5cb06ecdd8141f04f53e5a8e50c0a3d3392916fcefb0707b85b7fb), uint256(0x18e98401fbd4f06bb20bc69f4930adbf1a271f374412f98076236517205f6690));
        vk.gamma_abc[111] = Pairing.G1Point(uint256(0x1365b4bf9e980261a094e5dc90ddbda2a8a2e12442a95030349a5deecf4558ea), uint256(0x0d0bfceac44bd4a975447d4f2092ddd1432ac6e68c424015233911e45b7dde7a));
        vk.gamma_abc[112] = Pairing.G1Point(uint256(0x22b632d6dddae555606041d7c6b8f8c04c19f51bbbe757607d7909287c9c7421), uint256(0x208a758ab274ba2e34470ecc00651dd36100a0c385005d7dd4c3d211b2bf51a0));
        vk.gamma_abc[113] = Pairing.G1Point(uint256(0x2fcf292ca3ba8afa074e614359bfa4fc69852efd221883d5e8fc4fbfbff0ca30), uint256(0x296d37329fe7f23db1e0b91a1d410a143eff2b98eae747fbe8da688ce08984fc));
        vk.gamma_abc[114] = Pairing.G1Point(uint256(0x01847f6bdda7e9ce633de3ba3f7f0eb33b751c2a8eb8e00d603ba31462674520), uint256(0x0720bbe850dfc3d66382f0938f899f905b6f8b43b726721e72a2293bc6221041));
        vk.gamma_abc[115] = Pairing.G1Point(uint256(0x2e874c642e5ac18bce40e53b1bc792d6ab4a295406f4019e4943c28a57bdb81a), uint256(0x00c7569515a83b0ea22ec9332066129934fc88121e6586bcc7a0f77cb870be07));
        vk.gamma_abc[116] = Pairing.G1Point(uint256(0x28d55f28d0e45d85f53c7ee4a67934b1dab982667a4ac1dceb7162b909ab32dc), uint256(0x19a8997607ef0ffbf1c99753316eb8b5b9af491683f335c9423cd236951bbe7d));
        vk.gamma_abc[117] = Pairing.G1Point(uint256(0x24ed7bb7ded2e883e3a3dc5eb73d155b989b01a2626cd2a2b61263339feef98f), uint256(0x135e163ea503adf9b8e138d1368cc8a88b1ea5d49318bc9e1fea1f24ad63e272));
        vk.gamma_abc[118] = Pairing.G1Point(uint256(0x0e8e2c6897eb5e5985a3652be352db60698bcbad1848fee813b06f0f175bccc9), uint256(0x0bfbd7e1b6b369afca779dd2fc9cb5df4d8b099d241d7371dc177c8d6d6f64cc));
        vk.gamma_abc[119] = Pairing.G1Point(uint256(0x02b184da744926563eea7b57b1a5cdc97ad342a6b6a230c8868258639b6a2657), uint256(0x146f818eb4e79a4d343f87d1550016315ffb770c49633156d9ca5a65265dccb0));
        vk.gamma_abc[120] = Pairing.G1Point(uint256(0x1406559c00c581b3b522a86d98b347bc135a73673bfab1ba3fb8156911c8336b), uint256(0x05c84c84cb32692bc91675f5214371f5e123fd39abed46a07dcbcefc63a6d67e));
        vk.gamma_abc[121] = Pairing.G1Point(uint256(0x2a33980bb09326a7840b9451479991faccdf1de6800e555cd2b2ca970e9a6ab2), uint256(0x2de8a5e112d8ae133bb09d6136eca6a4e56cf75683f3e488dc3a9cd026f9332c));
        vk.gamma_abc[122] = Pairing.G1Point(uint256(0x23d2ca055f72779bfe6c7b7a1046f971c84973277e8c3a124375b2734fd88fb5), uint256(0x2ad014539a679850f93c249bba9a1c36eb0da55107bacfcd538860b35334e2ae));
        vk.gamma_abc[123] = Pairing.G1Point(uint256(0x15c7972034256607b4aff810a00203f9029a75f3f01f29d41e59269b985e69d9), uint256(0x246e12fcb081e1898827e3df935e9766196c870a98d0804ac43f443e5520e113));
        vk.gamma_abc[124] = Pairing.G1Point(uint256(0x02267f968f19b743ac8135734fadc366e21713969e96500349ef58eee21f60b8), uint256(0x0c8eb3812d9e03fb67a628ced2d3aeb5c803f40895e8c62eae9369bbdd48ff19));
        vk.gamma_abc[125] = Pairing.G1Point(uint256(0x2fe173bcb9036d7fe82e1fe671e785387f4a4b70ab340d4a6782630baa7a6cf4), uint256(0x237d97d6eb5049c3ef476a177af9650d1dd5c512becac7b3df64034361d354aa));
        vk.gamma_abc[126] = Pairing.G1Point(uint256(0x0a6809196f35368f8a6173b3849ec74a82e0784f6b0722ba493fcf6a9ae9e291), uint256(0x2f9268a3fcf1be3086526bf5f9e4f39caf08b03ea6173a3a71f796ba79afd2ba));
        vk.gamma_abc[127] = Pairing.G1Point(uint256(0x1a3fc2794187586f4d79930002ccc3640cd1a456df6b5bf2410dfb561f7761a4), uint256(0x2c1e1228d9710a04b2c136b7b193cb512be4db73710e95b127bcc8123b3831dd));
        vk.gamma_abc[128] = Pairing.G1Point(uint256(0x07cab370efbbc594b225d4f088cb952b8415f4b0ad91d6b58e4ed53ad70ed236), uint256(0x0152fdcf33eea5c4c78e0be7dd414d0cda728a449c87c10134df8555a1baabee));
        vk.gamma_abc[129] = Pairing.G1Point(uint256(0x0c3d3c829f459791953e3e76d45b7999b1fea733bec418cd59093fc9fac55d92), uint256(0x092d4ead9af6ef6fe4764de2077bce9aa9be551bc6ff842b25a87ae1fb50c10e));
        vk.gamma_abc[130] = Pairing.G1Point(uint256(0x190a1323282a4f7432548e12189bdd0905b6e20c4efedbe2f3f1271b559ae8d2), uint256(0x298a0649cf304296f2ae43791dd6efe1aec656346c555498a62a5dc36a6aaeef));
        vk.gamma_abc[131] = Pairing.G1Point(uint256(0x0e6cc508000047b5695a427c5ed4188e3b2adc5b4f0779ecf54c961d80a92c35), uint256(0x1355dd9b04eaa87b385698d45fc247c2dc466f31c6bd0d0bf8a5e75bd39dc94d));
        vk.gamma_abc[132] = Pairing.G1Point(uint256(0x133be57cc89357b274fdef0fd6d3f35ed1ef4a8aa45355d567c8571ff9a1ebf4), uint256(0x0c9559a7d4292bf764d5f0bc07e3e8f3d140320dae6cdd5165fa2a86427bb7b3));
        vk.gamma_abc[133] = Pairing.G1Point(uint256(0x280476da305a03cd4d13aa5687f9f37e59b20c83d90242393d07370ddd0effb4), uint256(0x2b837cd2bc2ae7a85defc9faa73faf21b3438c870eae91b32fa333a89ec3ca27));
        vk.gamma_abc[134] = Pairing.G1Point(uint256(0x24abaaeab3c41541989ce39b5485a1e03061a56d353e5d6328ad914c6b103d30), uint256(0x1d691ce6018c0cf2ede56c2d2859e6b07240df063ad91794a756e661c85c3afb));
        vk.gamma_abc[135] = Pairing.G1Point(uint256(0x0c5a62be715bc1397037c9ef269771df541901745748148f10bfd79e1dfad470), uint256(0x05ecc89627dde8d2e92838648ecac3c8ffd612b58f9aef9d67398dcff7d5b7a6));
        vk.gamma_abc[136] = Pairing.G1Point(uint256(0x10271cb634bc402f28b20ce5362359d321a0a65ed31fe1c3b24164be8f54da97), uint256(0x14a35de67928078580d635c48039f8171cf6eccf57cada2b5ae2d942b2a6c0a6));
        vk.gamma_abc[137] = Pairing.G1Point(uint256(0x1503f2acb1150a40355eb8d667ca2c8ced4865e2978a6642c71a82bd07c2494d), uint256(0x1ea49e4a1fa72343ccb318311899dc29aacf54ab307df919077a425b69d42ffd));
        vk.gamma_abc[138] = Pairing.G1Point(uint256(0x24abf1589748afe82c8cdb43f71516036392a88fbeffe25818cfc4369a78e765), uint256(0x2d5b27de917e8e5d2bc62bb04bfe8b07741d9a6299e7a26a48442a284bb4a1f6));
        vk.gamma_abc[139] = Pairing.G1Point(uint256(0x1001be11ac5fa2912d5e1b7857d29028e8aa1a78cd101cebe42b08214f06e632), uint256(0x1c1f9c6534ece69dd15f735465b29092b3823c822f035b5f57504e0155810b4b));
        vk.gamma_abc[140] = Pairing.G1Point(uint256(0x168bb81b32a17b43dbc8c55c0c2a7f8061fdf0b50516e3a7fff86998e75340b8), uint256(0x0d765f943ae0498b1dd4613df95a09bfe0e390c46fa4c9bc509bb4b9851f5a3a));
        vk.gamma_abc[141] = Pairing.G1Point(uint256(0x2c41657e50f833704856f4366060d2c96c01db2cdf510dc7f77b3f86857b85c2), uint256(0x282ab47dbc9582b712b2eadcf87ab333e14057af9fb8a33403c0f5b52a4cdf26));
        vk.gamma_abc[142] = Pairing.G1Point(uint256(0x0cc6c4a2f983baac5d1e558472a71ac6fe19b6d620c865bc162b47671c09b246), uint256(0x247a9d8e72090efa70682680a565ef97e73bf3ca62dbe243bb57109c1b49d429));
        vk.gamma_abc[143] = Pairing.G1Point(uint256(0x25adff52540cf7cb9bb4b0da066466c7dc7d937594d62521f71df590ca243ad0), uint256(0x1dcc154ad9d3c7b1f8de1a77a647f3d24ecd37e229d41a90478f74cf284a7a7d));
        vk.gamma_abc[144] = Pairing.G1Point(uint256(0x264646b3c2cfad56ecda5ff6f8a6d5a00ca6ed6a23445c42ca5c6765a6e5899c), uint256(0x007699db9031560d9a4c6087fb654410466293b6e15d09a059ea4e6cc3e8a8ef));
        vk.gamma_abc[145] = Pairing.G1Point(uint256(0x0353b5a7533b9086c3be3f8d2dff0766aedf93bd261733f807bd3c6e262af89c), uint256(0x1d3c3a4f2c52afb5fc9240cf3cb166189b8e0c93e1d1d66289f181c7202e4560));
        vk.gamma_abc[146] = Pairing.G1Point(uint256(0x272a15752e7bb63ad49531574bd0083963b444d37cc5cb958cf8e47cdee9cab3), uint256(0x0caba3a4c0d1cb0b156de4a63e84ed221bdd37ff00e8757040b2fcd74c6c345c));
        vk.gamma_abc[147] = Pairing.G1Point(uint256(0x2319c73636a6c9ee718433b5e77e4abda4c45a9a2db002e131f3147e40c0c507), uint256(0x144ad8ece062a55c8b98580a7f2eb142a0017bb1c1ea1e255e6bac46822bcce8));
        vk.gamma_abc[148] = Pairing.G1Point(uint256(0x23b24c3d8d327e113b5f9f52cdee763eef045dd5a7c504eb25d365a711248454), uint256(0x2f3e92a3e1ac66317beb099b48e7e04d5d039283700cc3bc0760fba7101ef033));
        vk.gamma_abc[149] = Pairing.G1Point(uint256(0x04585c5349de8965a2f4ab040245920571d55fcba5608ad8550c4b919a07d51a), uint256(0x0aea5f51e51f7e8d18e37ff57ebfe7cc895f4ce4d44663fc6bea30f6d13ece1e));
        vk.gamma_abc[150] = Pairing.G1Point(uint256(0x03edd4373a9107aeda5441f705b7da97040e3e649de48e9b2d5dd8c751072dca), uint256(0x301c62ed738607265efc6d0e7fd45a9619db0dc1ca148018c8f73fc1c98fe492));
        vk.gamma_abc[151] = Pairing.G1Point(uint256(0x166eb3afacd81ef63daab4a47bb899c02f81ebe5e1fb990a5d29fd0b4fd6b272), uint256(0x1388d0538e5ceeac49cbea3f963ee73350d623f4d221ab090b36e00a36479f86));
        vk.gamma_abc[152] = Pairing.G1Point(uint256(0x1f121ea1b309b8d133309f349df949b5d853f79016a45a72fde6992fc2677914), uint256(0x05e3000551af361e7b53b175de1383d1f24a2570407527f8d57c68e54e10d994));
        vk.gamma_abc[153] = Pairing.G1Point(uint256(0x0615b0e26001512775c8c3535b776c3c74006a733aa8a21c0c3f19028f8df2f6), uint256(0x08793880c227150dc41c6f4993eebd513abc182644b8d4f17f0c472e0812b7fa));
        vk.gamma_abc[154] = Pairing.G1Point(uint256(0x21ad97017ecbcfc27b2123a87b183da4353a4fd44126a8364ab8da937010884d), uint256(0x139d193e3f01cd61ceb7979128758a1aaf7d9263716969827df3ccfcbc82a83f));
        vk.gamma_abc[155] = Pairing.G1Point(uint256(0x28e782aa4a2a5eb71c2d36a70d9657b0c65a24f53321b67feaff233834494745), uint256(0x1e2fac22030be8bf6d8c490bf0592860e1e0d09c30e57f6b1525fcb86d6a1cf0));
        vk.gamma_abc[156] = Pairing.G1Point(uint256(0x1bf8e8cecd3f7d5f119e7e5218bba5cf6548896289f57bd9e953597756478748), uint256(0x1d3a31ed7879b0ce163869b6617ef23546b2f115fd2aaf200fffbc78d3cebf1e));
        vk.gamma_abc[157] = Pairing.G1Point(uint256(0x0ebe2a5404b35bef48cf1fc05a1fc9fe30fb6347fb62a1e2622354086090200f), uint256(0x27c1f570308086775ebf94e215aa1879dece8ac83b497d2c9aa08a4ecf1a5683));
        vk.gamma_abc[158] = Pairing.G1Point(uint256(0x0900be8dfd385ab0d2da8166204572731c289482e03268309bbff4fc69e8a7ea), uint256(0x07afee7b27b711e099f75ad59778293ac91f5bdb65e11c7b438d53ea67199c5d));
        vk.gamma_abc[159] = Pairing.G1Point(uint256(0x12ba525aa4cd7b686c5fdc69aac4cfb144e318fef3d11651054beb21c994ac87), uint256(0x235a834c87ed0beb94afd5069314b4ab22bf7718f33173d6403083eb9291adca));
        vk.gamma_abc[160] = Pairing.G1Point(uint256(0x2a0996e99514165cf034525377a19f0ed20fa2fef5bff1aa1f76c4467f76217b), uint256(0x245de8e7e59a5a98f4ef3f1e86f2ef4fa7531970b3061dfed32b8842f871db54));
        vk.gamma_abc[161] = Pairing.G1Point(uint256(0x20cbc7619fbf29833466cec8af16e532594bdc77a3a69a69db68383175d3ea29), uint256(0x2a181d7053f8a15af0fb391bf91827cd251e2f2138d99f40c8c44263dd6d89ff));
        vk.gamma_abc[162] = Pairing.G1Point(uint256(0x1bb8b6888341f421de5815c0e592d5f4e7ddda33f97ca9c005b0b941383e3744), uint256(0x2749057035a409dd60f87270991936958bb183314c8e3852a293b16e017dda73));
        vk.gamma_abc[163] = Pairing.G1Point(uint256(0x1577c7f79d28e4112c27e80cfb69d1d4076f3bd295a86efd499ca74d0d377916), uint256(0x163452c14f8f1607ab619c7bc0295ad364f519b9a95d657b199356f48c2277dd));
        vk.gamma_abc[164] = Pairing.G1Point(uint256(0x1e4ecc76f668ace606e9c9552e17d8aeb7a9681cd5ce39e6b8841f28a0f5cbf9), uint256(0x296f056dc803c92b253439068926621e2c2019f85df99d2426663ef0563937dd));
        vk.gamma_abc[165] = Pairing.G1Point(uint256(0x10358735a1c07ce13f37a3ef16a126e5de3c3dbfb00feb5dd7cd8bb050c7b356), uint256(0x08e1981327bf67ff41f55e16ffb2e954e81e8cc8f152f611dd80473639eb8c1a));
        vk.gamma_abc[166] = Pairing.G1Point(uint256(0x05d47f162bb6e93db9967bf66ef825666a3a173ba142c8e4ca87531ab6711320), uint256(0x1a96a948a350f516e1f1c4e27d1961839364b4a8bb9a247acb848474b140f78f));
        vk.gamma_abc[167] = Pairing.G1Point(uint256(0x112be4c39d6b7e42bc8d4d77767bb219cb18bde7849a1db46b0743aa23bca8ec), uint256(0x01583d5bb6c2104a166d1ba01ed987ecc22f9b8104b591071c490136f2eb548b));
        vk.gamma_abc[168] = Pairing.G1Point(uint256(0x292058800678260c4923538b9e20a1a56fa2c7dc7cd280659828e61bfe32f9a2), uint256(0x1b040f6fd449a8bba0727cb43196e40f70d9401bab9b50f6224dc690a8b1cf46));
        vk.gamma_abc[169] = Pairing.G1Point(uint256(0x277f6f868da3d2ac4ee9c3d41bf4cf468fe1eff12d29a7feb900011770449843), uint256(0x268f763a896cb299711cc42b258a04a704f6660eca25b62fb342b7b6edb9c67c));
        vk.gamma_abc[170] = Pairing.G1Point(uint256(0x1b80bdd636af9a63c4ae967fa98e921012d7f276272a13caecf8f36f7e0280eb), uint256(0x27c435b1010281d4abc66fd3b91cd81dfed7d831a7114ec964cf209646c2c57a));
        vk.gamma_abc[171] = Pairing.G1Point(uint256(0x20a7bb97d8b7361f4961afb9457cb56b9c67721ff1702b4997df469a5a419595), uint256(0x09b3a891717182966d05f0924cc25ace41b507f773ebc4ee1f3abdaddb95672b));
        vk.gamma_abc[172] = Pairing.G1Point(uint256(0x1a36a12af37b4971db29979fdca6792fe19150798ebd0846c735057212724db4), uint256(0x0c47a14298d65947f74c18b60adb57ad202f00fa761a7a5296512e8b80067262));
        vk.gamma_abc[173] = Pairing.G1Point(uint256(0x267139672249c429834e1985b14f3e1afd377bf6a2c722c6c3b1274e05348ce2), uint256(0x02627bd858935cf1ae04edd9e3125e547fd1950dbd637cb9c4acaf83f7c4af22));
        vk.gamma_abc[174] = Pairing.G1Point(uint256(0x1657b6289c8fb7950847312f91bbf537e01bd666e0aa6ef7eb155cbd47239c9d), uint256(0x018fa61b5f652a481554bf33369040cc2ca18e4cdbefac77b44e9c3d66c097be));
        vk.gamma_abc[175] = Pairing.G1Point(uint256(0x132fcf59ae2f5be0e8c0344981597c82f756300a582f63d1a5fa4bcacb88b990), uint256(0x1aa378e7daf360074cf06bfd36df62a77f250ea9887ffef92e4890b81107f739));
        vk.gamma_abc[176] = Pairing.G1Point(uint256(0x1c3b6186d89b4e6b5a99249ab5102fa0cffee8313d1fd92203e2b3bb64a4b755), uint256(0x24b7952cd41fbe7c6cf3a3504dc339a27c3058f1bdfbee8e8c0a4638af390eb3));
        vk.gamma_abc[177] = Pairing.G1Point(uint256(0x20e7bade984074c056754aa18c79c4bbb0049b7427c1ae062e78332f3530def5), uint256(0x14b1287ca063b68e5d3f1e1cd03acc12737d90380517595d53b7ae9205ae7d4c));
        vk.gamma_abc[178] = Pairing.G1Point(uint256(0x02d65fa8d9a68dcdee26840be708f8cd31ce1a9634656e03d2f03e3244d6126a), uint256(0x00c71beb3ca04ac03a929ec0f4637c1cb0dc2469f3e3147cf2ba99b9419f5b0a));
        vk.gamma_abc[179] = Pairing.G1Point(uint256(0x14ed533326d92209489aaa27129381a2a4dd8977344a74fc5e44b8d162aed80e), uint256(0x23b2afcc34270bcfd15a9affecc6d9d8a47bfd02a61a2f35c1090f49683e03af));
        vk.gamma_abc[180] = Pairing.G1Point(uint256(0x1e000508c3f52764db4c6c8781bd10219ceb477a1f164cca311a9c858d03e440), uint256(0x0393a9328f6fc3be9e71389325479b2c5a582ddf489e5b9dc2a22cb465a26fb3));
        vk.gamma_abc[181] = Pairing.G1Point(uint256(0x1052a8c2af6a2f0cf0bf47d6a1409dd8c805d35c6fe50e581cd44d92be800fd3), uint256(0x0d1bfc16002b9f03aa2dd2756ad07b40afeadc3f6c61a4874a4334658b9e1a50));
        vk.gamma_abc[182] = Pairing.G1Point(uint256(0x2e47585cf6405a85d827aeb2f2000eb3f3e72832dfcdb9454d1e47420194d2dc), uint256(0x0d4c953f3333ccb474cb58c38e47d51743c3067c97684c073d5dba366632d622));
        vk.gamma_abc[183] = Pairing.G1Point(uint256(0x0ec7060862d4835fa98453776e563ea825f555a18e6dd67f7eac431bb6a9a155), uint256(0x2ded462a8e245550698da8aba4b5214e142946bf1f232280fc29d0279777aee1));
        vk.gamma_abc[184] = Pairing.G1Point(uint256(0x08051d1eee86a94553819d89ad9c38aeeac93263d161f34fd4efa5d928bc06b3), uint256(0x23bd93c72aff18e2c5b6679f339d993d1e34fbcaea5d689114edf56eda1d1e0f));
        vk.gamma_abc[185] = Pairing.G1Point(uint256(0x1ab75175688f1de8516caf3e4e3263e3d36940f55071d597ce258812b59773d0), uint256(0x2e1a9a4b3cffd23216f2335dc89c0d804a621410461f0cf88a06beda8953dcbe));
        vk.gamma_abc[186] = Pairing.G1Point(uint256(0x081dca8be46be42375f4e7f38193d39bda2ef8db055b34990f7cd2ff1f2de61d), uint256(0x1d974f429bc9529a0c08cd9c446d6905024520e73e8c65794b99228f0af1a524));
        vk.gamma_abc[187] = Pairing.G1Point(uint256(0x220a2ee4f699cf0d7ceb839f21682ca6ced3af27ad227a9f8425bf617bd6df1f), uint256(0x28af6ef8b919e4c230bad2a4fba8cd30360fafe54dccbe5f0c2afd87d4ffbf6f));
        vk.gamma_abc[188] = Pairing.G1Point(uint256(0x167c138c617154285e9cfc63dcf191c64023294709d04c6a5fd1ec083197547b), uint256(0x1c2ac539caaf0d4134bbcb1b56fff18b30cd741eb14621f9bc1e2e585c69db94));
        vk.gamma_abc[189] = Pairing.G1Point(uint256(0x26aa249378daa375b0088f2f2ff08e08e604174daf1ca5f4c6328f6b5bfebdf5), uint256(0x2e0e91d81d0f1c4e304bf771109839f05958d9ac38b80cb119b87e3b064e1633));
        vk.gamma_abc[190] = Pairing.G1Point(uint256(0x20a02a05ae71bf063145b3e18d4fdb6e3237a29a19e3958f1f9279f5e46053db), uint256(0x2f36cfad850d2a1a54fdc491a428335ad063f234263504020614ac79d9852a99));
        vk.gamma_abc[191] = Pairing.G1Point(uint256(0x2c066fea3a6a7674c5c3f13b23895b87adbd80c95b230ba9aa1f47147221d52d), uint256(0x1bcd89e5d027a669868e233315a7d4a0fbda1a6ce4ca5e087587948cc5d31a0f));
        vk.gamma_abc[192] = Pairing.G1Point(uint256(0x1135c08f4b12bebcaddfdfcbc73f9b74ed1c121fe86b70567773bdc5e6d35b49), uint256(0x0f6409a0a1e9162e164c306b79aa1c0105c57b1bea4a91d31bfd9f021fe1d019));
        vk.gamma_abc[193] = Pairing.G1Point(uint256(0x0b67e079d4b95e9e6698bc7719d55b0f0184844877913d3811756de368a4cd40), uint256(0x02e2223c22b2f60958a968ed64abf72e9376e46d76e201bb88fcb93a36ebda4b));
        vk.gamma_abc[194] = Pairing.G1Point(uint256(0x02fc10f72f524742ef7c06a5a7e2001fb837280d1f52d818d843578348f81ee7), uint256(0x1f0848c4551a14b16f4329ee3a9ad5b1367d09228d07cd7c9298b5f37c813a96));
        vk.gamma_abc[195] = Pairing.G1Point(uint256(0x2c25e1170864cb61336c6d814588cda2e2f41a0742ce8ad0e11325ff0580028a), uint256(0x1e0626d533bc7abf4770126b7c9fd841baa967071539b823a49d7a5046309cec));
        vk.gamma_abc[196] = Pairing.G1Point(uint256(0x0a5a71e7192442bf78041556b3942d5f050e05cbd6094a8a2c1e273fa4322b9e), uint256(0x136555404c2f306a30c64f024707a8ed02f106e1bfffaf0451a7d9d87e7f609b));
        vk.gamma_abc[197] = Pairing.G1Point(uint256(0x064b5bd279088fce378bcd7230bb4fe192de2a0b7f568ad947f0b5b9ba14ef2f), uint256(0x0d7ce6be30d27603748c55f70dc9e64790bc89b8378a4e6db061ca1bf5c6ffcd));
        vk.gamma_abc[198] = Pairing.G1Point(uint256(0x198b6a25db5c6d7702f794ce8d97c2481490206db499327080fc87de2b935b31), uint256(0x1ade3e8f5bcebf18171bc4ac8e53f82b11e17ac24606bb051f59d89f1641c1ff));
        vk.gamma_abc[199] = Pairing.G1Point(uint256(0x2e1fd664e7a0c97a281b8dd98b9a592781f6fbdb398d839a7e1c123d11c6af56), uint256(0x2c7996fe0ac2237a3f708ae4270742f6b5dce81659ba7977619d81b42b94f71f));
        vk.gamma_abc[200] = Pairing.G1Point(uint256(0x17c40f3ea8a5ecd0fe727e7bf7a04b0b1b60670b4aff35e7a6bc3dbf7ae507b4), uint256(0x15ceeeb0ff023f75f510edd6fef9e5ae6d6883cdc72081832c44f186e8c32e5d));
        vk.gamma_abc[201] = Pairing.G1Point(uint256(0x010ea221df62a88ffc913fc16066b1d980c2d69f675cbdf896b103dcf4d32cb4), uint256(0x1b6a77c94fcf41a95e783fa8f61449cc6fec8f4dc13d0e878c3383f383c823cc));
        vk.gamma_abc[202] = Pairing.G1Point(uint256(0x0f21e2c4551f83e6949029a1770c4b9fe5ae9352d2fa7d5eac1391de9a9780b0), uint256(0x11fdc5d39161e457318af01239ee13abd80f7d0222bee7d3743147465009e981));
        vk.gamma_abc[203] = Pairing.G1Point(uint256(0x06e13dee239d887f6f121fa361b77b43672d9f78cec07bd38b8bd1c139899c57), uint256(0x262c27aa6c73f8d773d7bee4de96b95d155ed3b7020f9cc2cb137997cf13b011));
        vk.gamma_abc[204] = Pairing.G1Point(uint256(0x1382169f7d16da73b6a3bb62f0ae9fdd0cf911f227033c42fb50a127a12a4562), uint256(0x1c473230dd9221a82107194cdef7482fc88d0d5f1268ca1885c4cc15d460b1dd));
        vk.gamma_abc[205] = Pairing.G1Point(uint256(0x1cfea78bd365b9b4216b00a4e0ed027a433e1b6fba030d63373f105b9d719af4), uint256(0x2bc2fd97e480a40097891fe5c68e097c3c63101ba98ba309c1a5013792e33932));
        vk.gamma_abc[206] = Pairing.G1Point(uint256(0x014ac3d6f6012f69e5844bd6d32031361244a5a767e83defeadf6ab30f871a4a), uint256(0x2b0bc60c2a16d2496c10a8972bfcf058a1de7b881b7363f71e47176f1885967c));
        vk.gamma_abc[207] = Pairing.G1Point(uint256(0x21f0fb5acf3cd936dad77b8778f1821c5401e5ae3c9f692b35185cfcb7a4c73e), uint256(0x2cdcf1cb9a4c80e04fa558f19adc3decb0785c5991f4c66dae052a9aca88ae2f));
        vk.gamma_abc[208] = Pairing.G1Point(uint256(0x17df53822f9de5b12081b4e33a1a0acd3769f229ca27e86b116672866c1452f3), uint256(0x047f3dee9fb5feeae8c6cb4dd229e108c2ba0b9704f6048c3b74c048ad8a637b));
        vk.gamma_abc[209] = Pairing.G1Point(uint256(0x1649d6b9f520ff3ee80ef6465d9cad486939c4af8584a4b6ab9a594a10ed8ea9), uint256(0x28ee5e80a9692222b46565b0376353093b4dc8cc716bfb6b1bbab876dff8dca3));
        vk.gamma_abc[210] = Pairing.G1Point(uint256(0x17da58a0c8bffbef781889b11828c43233fcad8cf1bd0896f534fda3585ec1b2), uint256(0x1a0c69b7027cbd1e0890d1eb28615b2d41281248e0f1adcdbd1cc786b057f59b));
        vk.gamma_abc[211] = Pairing.G1Point(uint256(0x0ffe25b09dba66c85f17b5b08f2ff04236f9ce23a84a2bec5f302ac763b5a907), uint256(0x2ebe3ab0a09efeecb7f67ee3a56de37c403ab1bedd948251d89fa4546be9bb7d));
        vk.gamma_abc[212] = Pairing.G1Point(uint256(0x0af2ff06b31641988d0555f47cf8385769f9c41b58ff2e611dd34989c88b44b7), uint256(0x302c8b3a2b502dcffacbca001d7d2144fb7bec2e8bec7d482a9c2d2ca2c07229));
        vk.gamma_abc[213] = Pairing.G1Point(uint256(0x1f6e090abce279127ca5ee033ac272c1b3ab4c42488552356c36ece1bbfd4f34), uint256(0x095d9d0844cedb7c5e3c5b55c8386a87a441793926c90e5ddd57efe8eab0b3d7));
        vk.gamma_abc[214] = Pairing.G1Point(uint256(0x2010aa32eb9b122c1805368a03014666d4a9335495f688286ff140109b939148), uint256(0x0e5741fdce12f3690113730197fa070f3ccb9ce90929a3517cb3958b00576207));
        vk.gamma_abc[215] = Pairing.G1Point(uint256(0x0d0364307f7a8ad96496cbbc897ad35f2aa8394fb56765477990199d5919537a), uint256(0x1af81b69bcb57d31aeb64c32978f04589d8df99c69e0aa9f1b5093f0ded4539e));
        vk.gamma_abc[216] = Pairing.G1Point(uint256(0x274425fc7c386d0df10024d516e20700caf3c8117c30701359e91181882685f4), uint256(0x2bf1b3180becfd5be2a49f1e99c4743841b7abe4d401dc6e4cf6186e3a42dfb1));
        vk.gamma_abc[217] = Pairing.G1Point(uint256(0x0969debedc94ea28d888f82a4d559000290ff65132e020aa29d7f984b6486cdb), uint256(0x107e4bc2820de65814fd90cafd43bced85545d5cd26bbdfb5487cbe925078abc));
        vk.gamma_abc[218] = Pairing.G1Point(uint256(0x22c44e4887f58a1b9be435f4ee5a5c71f1dc35f45fd92058a5adc72a38c288df), uint256(0x1643dccd92cd4621cac1ee5905e63fe95772311db08164cf3c1e49fc9918569a));
        vk.gamma_abc[219] = Pairing.G1Point(uint256(0x17c0983c92fc673bf89c2c2fd2729a608fe467ebc24bed764b8a56514bf9a198), uint256(0x0f18f0dc429a0ebf4cf4baf0d117ac4e78bbd962f013c73d5886b6c4ab75f55f));
        vk.gamma_abc[220] = Pairing.G1Point(uint256(0x23eba4cd9944d994f53191cc300be6381d33b8d0da696d6d410079af0b6bac9a), uint256(0x29691f9e59dc79bb0abe38e2a5f6c68b1ecf686cebe473c22751ec691e3476e1));
        vk.gamma_abc[221] = Pairing.G1Point(uint256(0x04411ceccde0cefd710f2622cfbf1704d12273a7e31d26ff79b483d4821b8585), uint256(0x01e18868df62a2655d371bb7fe7f677683917a25b93ae29e51ba250d3c80e73f));
        vk.gamma_abc[222] = Pairing.G1Point(uint256(0x2e033dc0472256dccf1f91478a2eac5652fb02615d11ac9a362cb526ebc99797), uint256(0x0a70aa91539fa4f6bb2b53eba665721ee2dade5ab3bcf856e319a41dc97db4f7));
        vk.gamma_abc[223] = Pairing.G1Point(uint256(0x0d69ffb9ef52005c2db31442f56c0181dbc2f9cc16b92f07f5045938c71face3), uint256(0x11bfde6f82281b7dad4ae16abfa586fb8e4ef806bb844a6c1c1996766cfe11ea));
        vk.gamma_abc[224] = Pairing.G1Point(uint256(0x1a2a2d28c2334c13c7fd5f146c3878b7802c9f3bf8270621facebf65c9a1e72f), uint256(0x1a246080f00837787cd70636404d5bdbcf7fb866166b1df942bd099cf42662a8));
        vk.gamma_abc[225] = Pairing.G1Point(uint256(0x1906c90ce0dec5effeb9fd544afb8fb1d1e8e22eebd66d9ec10429cda7d9e06f), uint256(0x265c27f0905b805f482950cbac2b752081cca3879c350a39598bb36b7ffe0532));
        vk.gamma_abc[226] = Pairing.G1Point(uint256(0x1063340353c61f416466b2da1df46b14d5a9b7de79434246609770ac8ae6c866), uint256(0x0ad1c6909624f93aca6a3f3293386078d4b19def7f9cdcaf764fe853a3a24074));
        vk.gamma_abc[227] = Pairing.G1Point(uint256(0x19d899c7b2ab79bba43f668b1ea8dea7b5f77ca5cf5e8b8b95d5454286dbf7ae), uint256(0x2c05d79a13f226b961c91a3c896672b1ca3ea27eea33ed59bde9743dcbab10b3));
        vk.gamma_abc[228] = Pairing.G1Point(uint256(0x0fc1d9b508ead4489686ad984d85375e8b1ec8a91ff751f9263fc5271a255c48), uint256(0x03ce601e49502e6c017227d511f37aee2486781464e0e072498e0f9cab267d02));
        vk.gamma_abc[229] = Pairing.G1Point(uint256(0x09e518e9656943adb7c9146570a427618724217be6c4ece7b151554fabe76ae2), uint256(0x15e8c25da2f2a8dbad3a8cd88adc8cf653c1632cfa471402a3ed7ec43b55c6fa));
        vk.gamma_abc[230] = Pairing.G1Point(uint256(0x0f46b491703c64c461379ecc5db1ba9e8cce836405073acf61c6703030ffe6b6), uint256(0x0f6d1c5221b4fb9cd9908014cd13f787f9ed6cdbb9d95c1a7494bd01dbf08c27));
        vk.gamma_abc[231] = Pairing.G1Point(uint256(0x21ef3fa322c649e9233d04ddd65bc95ff9636c3be7c18372b152e5f30414b389), uint256(0x1635c773a8c25f84f28ed5d3d02678a2ded06a0da8e7fedbb5fff3fe830bc99f));
        vk.gamma_abc[232] = Pairing.G1Point(uint256(0x15acc930982300f0de7fb0b95ceb150b14da58d9d58c2db5d3f322c8a42bd69d), uint256(0x270e904c84708995c2cec250dcb58d29abe61e13ec88bc135690305d908a8738));
        vk.gamma_abc[233] = Pairing.G1Point(uint256(0x21e33fcd4f8ddbbb6fc27bbbda03d7c4b0341b461e5ffd9f889c399f1c91bbdf), uint256(0x245745132dbbb0200e19007324ab7712d02887849701c2eb95cb3514cb9b200f));
        vk.gamma_abc[234] = Pairing.G1Point(uint256(0x216d0130acfb45eec585f61e48135183203b1c36930dd2f2fdc97bee0246a92f), uint256(0x1aad538782bf3080d182f24d4d4e804c15aec880d7df41ef109deaafd427aacd));
        vk.gamma_abc[235] = Pairing.G1Point(uint256(0x1311259011e7e8f9538815d238f08d489eb68230b79cbe5c87aff94a0e297caf), uint256(0x034b8d00a4e78e465d2eb269b5e73f1dbf000022cbb8b395e393166288e54e6c));
        vk.gamma_abc[236] = Pairing.G1Point(uint256(0x0aff40ad4746342627227bd9b11986ce0923aa4b4b0eadd4accf175d58b2bcb1), uint256(0x0619335d9a1edf75a6ec49b4a28d365561223031bb0d21080d60dbc43fc126e9));
        vk.gamma_abc[237] = Pairing.G1Point(uint256(0x28a98860dd546d0948fc2b3de377035fbb1d34e31bc4edf881375133c8127054), uint256(0x19d85709726babfcb3c0dacd53cf7523d791355db626189b54a91a623f7adf43));
        vk.gamma_abc[238] = Pairing.G1Point(uint256(0x2eb9f0922319373edb24b22ae158e5fb4865c10f8ef2365529531dca57e3d572), uint256(0x1d75a82ae299df4ab29ea81fc871b262fbc48f3f10a628e18ec250990b7c0468));
        vk.gamma_abc[239] = Pairing.G1Point(uint256(0x271014edcd8a453d3ce210dd701bc5d3bf868958f4d609fa355b4e8f94a57039), uint256(0x0dd7d4840fb0dfa850f9ee3c4f7e6a07504462f212ef50d1144df0b66afff678));
        vk.gamma_abc[240] = Pairing.G1Point(uint256(0x23a1c99b6652b82df17d760a7da8ed57f7e9bfe103241b3df55496d73133bfa2), uint256(0x2d4fae574a3f70141698d5fd561a6d69ca28ff0f27df96f72980ad60baa92b02));
        vk.gamma_abc[241] = Pairing.G1Point(uint256(0x2b7769aa0f068a67ebaf6afbeb8372a6d6db83dfe820f300f1445c9e79c7c6bf), uint256(0x029df1f43c8a4c9e80f7e17af487776c799868f34bdac28d0a69a3df35120129));
        vk.gamma_abc[242] = Pairing.G1Point(uint256(0x1ef5c98362eb0183ae7cb8854c5fab6fd158a70c87509776f63c13a068d52b81), uint256(0x23d7b4015272ca64442f497f0d54aebe11195f1137295b998ced699127c8157b));
        vk.gamma_abc[243] = Pairing.G1Point(uint256(0x22e5b3162b5388306f16b255746cab3085f2d006c7ef70b8726b7e4ef4a39997), uint256(0x12f400ac38ab5eed3729d93c5ff130fa4913815d7d874b35ef497783f2c6b3bc));
        vk.gamma_abc[244] = Pairing.G1Point(uint256(0x0ced78e7143000e6ebe19c719178098ace822e7cb01b25321c9f0277e5a44dc5), uint256(0x17a8662d15ac69b1eb21b0aed7244757a41675d3d1c7ad8d3d99dfca16e84bd9));
        vk.gamma_abc[245] = Pairing.G1Point(uint256(0x1e3ceef36cab53b71052eda5474bc0c57278550c4b2b09c6fd39fc5eaefbb4f7), uint256(0x00f8185ce5b882a75b15743d5f1fac8bfac225203e3f7f83b903b7135616d91e));
        vk.gamma_abc[246] = Pairing.G1Point(uint256(0x2ce2b7bb29c3abffd25cbb0da063d023d70b62da146260e8f9dd716c99a44d6e), uint256(0x0e1e4ef72cd9dcc03935f0c13f89a1fc586966288c251cb7a3c68762fffce25f));
        vk.gamma_abc[247] = Pairing.G1Point(uint256(0x135bd095246d2f60ca2392ff6233682fd15e3d0eecc5bd12e1dfe72f62da6f98), uint256(0x273ac4388b64b4f34c56a94fea18f158ab4bca48b4ecaa2f8887f055ff3d99f0));
        vk.gamma_abc[248] = Pairing.G1Point(uint256(0x053178d1080314547fad5de37a329aa712135dda4439beb503cf58885992ad69), uint256(0x1bb84a47f66664987e0a01404535c78aad441393c17377f06ad21a00f4ae9d91));
        vk.gamma_abc[249] = Pairing.G1Point(uint256(0x2b281028c59e77dabc46e58a4954386d209c21337431d8f3556d95600f6cb688), uint256(0x141f65523a6620a86591b37f1002e9e9c70f501e4b030ef8f92b645755f36f5c));
        vk.gamma_abc[250] = Pairing.G1Point(uint256(0x0e8a4db0c93ec9f11b73926ff3cbbedf28246462de4fd8b61de73ffe5875f6d3), uint256(0x1a70af98eacb550c6e675193e4a61865d522816f118d9689b55796b428a71cf0));
        vk.gamma_abc[251] = Pairing.G1Point(uint256(0x2005c0a6b0c8476e8079028b269e7dc53c46b02ebad82858451ece2d40a1fc9b), uint256(0x238d8fbcae821b3a98c4e2d8dd1f919d9c76861b5c118ebefefd4f6ee0817e29));
        vk.gamma_abc[252] = Pairing.G1Point(uint256(0x2a5215a69c9c26bb8df97e1fb428ad1cddc379d4f8fcf3fe8194e711cd2f9f0d), uint256(0x216105a01540f6b0cf032606175d3d814367f5474fc7705f6f2edce880c39fa5));
        vk.gamma_abc[253] = Pairing.G1Point(uint256(0x21c571d8fced3aebce963658d7cb83d4a32e3aad9f741a858db7fc67b29f75f2), uint256(0x049eb69b070a430864aa06bfd11fa1afc0209d97512f39f7b55105fcfdfe77ce));
        vk.gamma_abc[254] = Pairing.G1Point(uint256(0x05338740231371166d17455c8ded64774b4d9563dfb17fea5a693eae94867157), uint256(0x27f6ada817b34d3ac6b69c556f39174df992dfe6aa6c898ea3f2903e82cc203a));
        vk.gamma_abc[255] = Pairing.G1Point(uint256(0x17913abe2c89bec1c797cb7e56fd754b27e9d9ef9427a71fa3fce297d8970c29), uint256(0x0d2d36ee02e91c5339a8692f3f24b84b6ab5ef0b5131301f69027c7e3a884ed4));
        vk.gamma_abc[256] = Pairing.G1Point(uint256(0x18b6afde5b1a59e72610b7b194f5785ffb4ac673a1eab170deec0f7fe1553f3d), uint256(0x26a7501b4e070ca81c841a8f172e24300151abf4255f407f158bac4b53597742));
        vk.gamma_abc[257] = Pairing.G1Point(uint256(0x11a16e0ce07caec03911bc4f3f370676421e21d3a7ad83a72c3bf163bdd9501c), uint256(0x0e56390b187e5a1056545515fe3292ebaa1c7662c2266d0766cd56876f4f5be7));
        vk.gamma_abc[258] = Pairing.G1Point(uint256(0x00f20cbd5c9b3cadc4d21709377b892b42d33c5b92b35decfe093d763167b9d1), uint256(0x18708df5e1cf19eec31fbe1a59b7b7b740239248e1c67575e266decba780313c));
        vk.gamma_abc[259] = Pairing.G1Point(uint256(0x0d5b130dd153ee058549823b791e7bcd8e44968848e1d44760cb994f74110576), uint256(0x1ce3584537dc8d284924ea19e8eaf134c501b015d6365d084b5f7ee558639ace));
        vk.gamma_abc[260] = Pairing.G1Point(uint256(0x2871d1362e6b65f36977d910dbf9984def84dbe3e94c48a6027b3a2fb7468369), uint256(0x0c5bb742d9ef8882852d6f0d320214a15e5a99148200dc7131d7c286df8e7b3e));
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
            uint[260] memory input
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
