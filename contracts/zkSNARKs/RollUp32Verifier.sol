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

contract RollUp32Verifier {
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
        vk.a = Pairing.G1Point(uint256(0x179d8664dac8f18a40c98a7b40416aa1b0ad5154c1938c414f159053ef2a9ef3), uint256(0x197b45984952616e500e13b84e5217ff8814124451164dd3c1a6674e7d148460));
        vk.b = Pairing.G2Point([uint256(0x29b52e5e0cb96befb2711b22221ebd77d7dd4b6cd81e353070a9f77aa87cefb9), uint256(0x1cb6115318f177e4508d423f825579bbe303e0c05c093301d6d8a92b2c820237)], [uint256(0x0fb4f7dcfb762304f774c6de9ad1258af2880424ab3a0a17166c475fd230726a), uint256(0x2720c0254ea3f83aa53e2b5869247089eb187b79a1adbd436222321b083f9f43)]);
        vk.gamma = Pairing.G2Point([uint256(0x0413e847359c0f155611875b776e99eed2b52de199cacb196f00cce1e10fa660), uint256(0x2a6e0e7b6d7ab631cecabe467d548dafa690e5079c1ec006249f53b569b0f4a1)], [uint256(0x12d51508060f446f1513a8ac0e5d083281f69ce95867ba6d436e6186929e5ac5), uint256(0x2c43bdb08cb127dbe271c0fd969f275c62cf89804ac1b12a4d6020abe8a0ee0d)]);
        vk.delta = Pairing.G2Point([uint256(0x2e6256d8d907906a6d532e00eadfc4b9f665b8c9432b7544e5c1683359ebbeb5), uint256(0x3035a8649bfd477a8673a8a904a571be79f5ec54b63abdfd5884a172c5106650)], [uint256(0x161fc4d28081948bfca8e8f16b07c59fe803ba9a6308594edb253ef8a3c81992), uint256(0x2849400e321c1fb9d00e839be7b954b6d74ebefda31a0b34e4555d7d3d66d85b)]);
        vk.gamma_abc = new Pairing.G1Point[](69);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x24fdce230261b3bf49d1d622a60571474f735c3e289d27b7895bdf124d9abd75), uint256(0x0a9da749c733637b8813170cf34e97e7a1efb6d9799ae82211b8e8e7ad64d7f4));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x257c37dcc74e767895d1ba6c60185371cd719b14230ebf056e9553a595ec6530), uint256(0x030540ff5d92d8be18fdd78ebf48689e6b8832754cb01623cc006f40615f54ca));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0398115990fbc3a2192e952d7cdfba95d41d9833491d533be193a9170d6bde7b), uint256(0x0299313038617c94d566f107f12f00b000ca6eada8b6cd5a97b134086ae5a16a));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x24a5115571a53af6858e26c2ffd1ebea3207f4d50f19749444ebd0fa5e627cc4), uint256(0x2ed08607f05968720be2ed727268e39e8ad59dcff5f261701bce7fb04bdf8e75));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x16be158c2678bd91e9943fadb5d6ef3135bf10da2b0fd47a62c0ae19a676861a), uint256(0x1f90cb76d03a05f97d09e5d932b0c63af3e12c040eaf2779bfb63790e034aebb));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2c8bbfbf21fb6d7f38322aefb31fb0bd0595b702899144c5a2b62074586a22da), uint256(0x0870a34f6ae645266a09c6f7c99f7db8e362439e864f43bdc26db2f2e96370bf));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1e20222b9a20427ed984a89460c65871c97a3d37aef8fdb90e6defa2d171bac3), uint256(0x29be321b81be2f737ad35cc49ecafaeaa6d23ba12ac64d061ca3137f71cb4c9d));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2f130e6d4fdd8f9daaee027a905af606504540cf049e8627258e99b9c3339ff7), uint256(0x1a6b19afd3c175f71efb763949f432883f00159c4338bdc4f160f89c782f018e));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x24a9363e1c42a7689acd05174e6bb5e76d2e60fc2fa275218c4fc1d0cb328c01), uint256(0x1d6184de292e8bed6db162b7a36f1a73686cd046266c8be5891196677d077815));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x077be00ec1650a15e734ac05f8ae6efa70849172f2165c9609ba50ace8f7e764), uint256(0x0b0446738c69c1008cae5ff44c5efcfffd7d7c2c94a4c5f1505f2d283caaf28b));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0ca9cf0f1b612a214970180eea82e8b22fdd99ea83ed0a880301f90045f85570), uint256(0x23e8e1d407cd117a509799d4d0d304a7001926b48da1458e614c7bfabb86741f));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x081d95e089fc1bdde5476d609dd119e37d4d8678bd84f7b410f47351dec1d2f9), uint256(0x0c31e3beb2ad60819d36aced0847162057b69fddbfea81145667821556ac5347));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x008b2d2ad5762fc5e97be8676f87107ed717b0105b252f5965813282d01a652c), uint256(0x13aa112bf872bee8fecf42567d3d2c851ff23acc5d5b8afe9e8bb715b53a9efe));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1d243be55f561b7c026fc461d3fc2b2ca8ac3862eed14d250e7f3d41c7f5caa3), uint256(0x020e9db41ef39c6ac5d88c51135557ca29c6c39db7f86a76bbedb7f7bbabfbe6));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x2062b85d94a0b3cba20c95363a2c6b7156f9bf85c15f7fadc131268d2f1a88ed), uint256(0x21875abe889207d6348506c2b8ac05811654e9c2efe7f8cf7b92a1d7d97038f4));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2e801fdccfc576da9ceb752cd41498979f82a70d60d1d7ee402ad26bb549c735), uint256(0x00835c9bacb7a9756bb71f43e6f72b580f10c645f3e63296aa229d5842cce31c));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0d907eb7847d47fa269ebb5b53677ca45990429c11c8187c93f7517efcb86d43), uint256(0x1b8d3f6b3e803609a07d63bf0db698d2ffaa7d78bdc3167115f7409762802a7d));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x26ccb64789156692f5d00b00e32780256b5acbbeecb500b92cd2f73c463dc129), uint256(0x185be9418e2c64e681a8d32ef4bd9a2389ded42c40bf948460a3bc16ce6cb976));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x2cddbf2866358c1964fb752cdbeb0b1393980709839e0260305c57ad37fe17f0), uint256(0x18895f4e985ac1655a78dbf8904e08d2f12802953f72e9655af2e21f456fdca1));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x024bb83e8e9705347a66a8458545580caf3064dc2ed81fabd6af6ac686c8abf3), uint256(0x2e5d627055575752d7dba2a0d209a90775311cc883cd3f6bdb4d26b1744eaad0));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x111df9a5413ea958b2629fea83da617b123a99bef5d0c9a20f75734bdbe68be8), uint256(0x20b843733b43d65e01f45774a0948ec20f594e5081b63a5e98d850e36e5842ac));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x1fac60640f677bfbbcdbd47eb08e2353264d34d0c9298e188d2079294eb29713), uint256(0x112632eff875039896a9922cfdc466414aca16783e6573ff8e08b3b22d734cf3));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x2d1eb3b56c53b8ef279fbab0912b6092978299d57c9e0cc40b39c57aa587ab1b), uint256(0x1279aeb2fedcfc4956c3b01adee459178bf141c8d3bd1a4544f1176745351371));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x025953453263437ed6a75596de19351243c78744a1450a6da69395b90a7e9c0e), uint256(0x1efaf45ec787c7bbd5b36d6f30a177327defde79a6fe4788afb6d900918971ea));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x1711a0be6758c878482e363c5b67cad1baa34b623236991193361bce8e8344d7), uint256(0x18c814ef9be32c696480cd5db67ac4004d94f38d3e6844f8efa354880c681762));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x2eed9d40729863fc4c3e451204c6fd809a1d6ed565daaa8adf263044ae184c0b), uint256(0x141af0e7e0586fddef38bd2aaa5b2caf610ba3017795dcee7fa077f3223d34d4));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x0c995b6cc0962cc337a812f3c5ea38965870c62a478b53ac6ac706438bd5730b), uint256(0x1db423bc76d74c409a4e7458929ea82b9f106e164fcbc3e2769d04d47c1c7506));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x3063cab8743b45f79492603729b9d66a74f7220c37d93af3d6303a6ae3cfdf88), uint256(0x1b322663cfaaa2edb0b496d621612517686bec6d77031192727e852a62a153f7));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x103d4114816bca8fce425a183931981e5a190b72d9601311967c02fb5a01402b), uint256(0x0b0e231e44526f5c55617c436c74bd354e846711369cd41f63d674213460b7e9));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x03ceaec55d51d42871a4e49f3fb67bf1616d97637924fae76ba8c1199c09a8a4), uint256(0x2d91a8b3f1e32378b3511617a0f4007c143dc43b109650339f1a1425fac5208b));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x068f248f3be815b3202f2a943f61fb30da3558cc4b1112aac3325998224c9486), uint256(0x10367a0214321d940cf3556a716aed5a4a654b60eb2c6455951145ef4543315b));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x0c66c608d11df62efe4f7bbde3fbde7c7a05c243d2b7274ddf878e5d531571b8), uint256(0x2822bf8e025868fcb0a1ac832b924e836ddbf6774037f388047f87a506b53897));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x1a945d4f0a9c997dbd0297f9f8bc388a5de444045f658c4af96e79c94fe319ad), uint256(0x0b66e6a07ee7884a8870762ee94d2a6bb0a8730fbba34eb90f8b04417c2b11fc));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x1ef944b4d36aaec3a44b8dedb996e00d7272db5efce1da9be4f7538b6702c261), uint256(0x21fa81f68b04a683a40c914d7075eb69b00aa71326c7e377b0aa41458292cc07));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x0e998391e9171b632d60bd176805a261ff0d3c05a23192e2d1905d1b3aa74ecb), uint256(0x0a58eae69b9295098071980a818aef9940947c25ba4baf4604db94f0f035679e));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x1b6387ecc919996761049a52aa71476fa538ea1c1d3dbc9c40244eaccb91869a), uint256(0x1f50fa3ee8541d8f0a3c6a5c9f3394325b0cfd961d08457c95693c9ce7bc2804));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x074eb103062423a945ec728d9439801014c74ddb1682c2290555972a07e5baad), uint256(0x1a73f9e28c546867b22530c4edb50d0de1eb71b918f07e37f05cac8770a766da));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x00419f375198043f3e50f5909810f0d9f92e02b507bdb0fdfc8f93f313fbfe6d), uint256(0x210a48610d835efc11d66fd0b16e5c12e9ec459ddd565fe767dec55b2fe7c0bc));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x168dfb207207527448736272f0c4ce83994b65fed383163acfe47486c184b708), uint256(0x1ecce9f079e214150cea0bb2cb31e8b846e41702ec8b17e3b99a876c818e20db));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x0f979da4bfbcb4f3f58e7e3207d3629c2d500fc25744f568733bef94bad46f80), uint256(0x29158cb506877e881d85b54e4852a274dd55a1173ae97d37276c5c8e902663aa));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x15ec1ceb34e81533abaa7f6cd3c6ef79d5cec0c0be170b0eedfa8a2b1db1fc8e), uint256(0x0ae19ab1c41f38c278b921fdfc96d3f99e2c4d98531a1288a41c9a2dbc538886));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x04401698513bdab1e354c3645cbc9b3199b82739895abf5357cee069b9d6a5c8), uint256(0x0b7686b7938e8e6bc6a7a0b962a8fd0a1a84d08fff5ff04365b684fdbc4e53c9));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x0cca9bc3a01d834f39ca461ad95f11d8ec00a83fd9ca799d8302058feabc5473), uint256(0x1f2c426fd4081b514ec162b91a8ac1ac8559a587a6438ce355a8a80f05aa24d4));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x1832c1ce7621d864c5a3eda0db0b34ae2f31b29bf6d71ee1daff3184dbc84e78), uint256(0x2e981559a958a6c980fee8839a6b831cc804f4df475e713e434df80786eec69e));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x2e33cbea708f803da23cab344959dfb9d5c0363c2655d8c499d6b86c24378967), uint256(0x0191daa9b85550ccad77f6fe8227fc7ab218db05fa83002fd09f3b795d0148e0));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x1289cd81c5aefa4a913584bb9e7dc14785cb18f7243262026c2130e2b4224c1b), uint256(0x00f8c804b45cf354add414d940e5da37b841a7a2e878215d690d3345938dede8));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x1d6a53c129bd5e45c78a3530a6aa05bb683f16f5c3b21c5e999f8b72a75d45b0), uint256(0x18c3de66bf2d6eb5cbed4fa422514efeb91bacd7c2e41cf2eb3482dc52aad4ec));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x21187e0b2091f476241eb8a7eebad8c1510290f0fa2227c6c1a8c526be37d1cf), uint256(0x2543b9e3a947e2223c3e40b0fe268f37b02b2e9ec5364b9eba23d2329eb2474e));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x2ece0ba3942f8e3f416e1b99a2630676ca3757e5f28994a98b687b110f4dcb27), uint256(0x08585f0b2a3e91705aef2fceb7e5aa9e32035bc1205fbd3ea118c75f948794e7));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x124bf2baa0f81b4441db8932b8cc464610ad7230e19dcd17cb66f79e5a205ccb), uint256(0x2e1fcc9b3db545d71659f7155d1f2b8457f6d06a0cfc9d54fcc56f7a8e64e2bd));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x2225728b2798c94e418811d2a28dbb7dc12feede35ca288631bb7638123dc8d5), uint256(0x1bf6fb8960b8ac14a1189543cf0d379c2b928244a4f932600f9aceb2cfaa274c));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x1ef7db93824033f2b65ed42a3dd570546352acbb6fead57454f909ba51542ec3), uint256(0x2ca13a4f1deabbb240a76a7bb65ee57442dee6bd51510525365b9dae4ae452f2));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x116088930ce4f7a2d211cb925203c709532e5b8804957e57503767c6842a1ddf), uint256(0x1a4dcc8e63f8e97bca8faeeca5221896eb6458e69d2e37cb1c0bffd2d8ee779a));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x141d2921ff3f7a77055be4e828e6cf7cbb21935f485c1a9b0bbf11b3df4cbc51), uint256(0x04a78aaddcda19157a17335b400318109e8da12529b7e8e236bc7bb9c77c29c9));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x2013991db7801ebc7ca17f502e1c82612db1eaf50df06ba0d5d8976170ca4656), uint256(0x18477ddcd8aeb37e9b6016376ceb4a6ddc4681bb388dbf7ab5e38cae316faaa3));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x14005218c110882ff21d4129e831a6cf50369e2b0683cf7b8755194fad298cdf), uint256(0x15996b464a07aeb46571c3b05d1068fb1ade82f71bb47fcb1853a7de95fc9538));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x2571e70668093daebb854cea2bfb64a60e8d7195c55965ab5c198674f4eaff93), uint256(0x2b59a8503ca05d0511268c244e34864be2c80c1f664654a44e76e9a3dde6eb65));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x06dbc68d768cdd8492ff1e61252e070b62ee2a8121928b52a86ce43b61b0879b), uint256(0x1a3cf2e7bd0dd4651329776126570f310a9c41acf49dbc1e968117fa4f607657));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x110f1aae78d42555edcf60ebbbb6d570799d35e430147d7c75e50f4ed7642b30), uint256(0x2c7dd111db9034ad3ddfb390d1d7fbd6483bb86c075d7cb3319150cc3b9fa6ee));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x07b3add4420ef5a580652086f0cf5b41c324a1bb49ffbdbb92efa7be98e2686f), uint256(0x22f7d638dfdf1d95e0f7b0453d820965273f20a69b27adef7d828a0d1db801cc));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x0c7a4af827dd89fc1153609eb2b23e08b63b12a6ca250d4473b4d84c7dae03cc), uint256(0x1cab462bb085b0e73a6eb04d88286a588b2eb73fa8ffdc0de26ebf5800bfde9c));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x0f66d3e3bff502342c77bdca8637a2abf8085570ce631db2ea01922af5c82fa6), uint256(0x035f44f62ebe900b9221a21f4ba3cb5b7a5c69c154b33b1e970f5edf3e8caee8));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x2906755d995c47d8341b3b8e4aabc5a7c7e0c0b8bdaf5464496513e5fc0e8626), uint256(0x0c4f43cc3cdbb135d24a17b27b3da1ef8ba2f6376eedb652b9f997d94c421860));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x268776744150fa53cc810e66e62b9c65c7c9317752555241dfa60641ba5d5201), uint256(0x2ed7441f48fe99d99775db87a0568535e5da7a88c9b4b40fe19acaeff5a49e92));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x161e2ff3804fc7b89e178d1ef22057ff89ddadcc84b46d9caed25d4f9c943460), uint256(0x1cb8c225381493f556c9095442fc7c762a7658450f624184ef71074f78de0c89));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x232eec6fe715db0143f204ff617a7370a561baff6723e02bdf5d2ed265be2567), uint256(0x1751c593c50527f7348e79e33c9e218610f9f1124e82ea9be259809aa1861d27));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x280018b84dafe1f625fc2bd03e1888ab61b228dcf8593eed8041b107f5d4c598), uint256(0x18c1a572d685a59e3cf349fdbb99e759180b1e482fba5b037d428254487cde11));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x2e43b1f39fd24a64400656d6e064b4822412705b40bf8ca4fde9a52548525fdc), uint256(0x1a8113f3f9ce9c87c893a10de206bdfb10e0ebe47554e174bd17b728e122bbfe));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x2f807ce08e668fd395b25b300146a9ce6bd16cacc698f83d0e7491cb8133dfd4), uint256(0x15d5050990956af62bb8d1dc0ef5377f8a7926e92de1345d13ef745894936452));
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
