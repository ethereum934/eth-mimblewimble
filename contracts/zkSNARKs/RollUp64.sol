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

contract ZkRollUp64 {
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
        vk.a = Pairing.G1Point(uint256(0x2d7d35413d886d2cf55558bae9d252a356cad6ecc54bb464436bbe8839134e66), uint256(0x15b8bb73c49c5e4f0b2442e708c370e79233a17329ae0385e4a610a8299b64d1));
        vk.b = Pairing.G2Point([uint256(0x2960bf922d38c8dbbaf5bc4c35872f290df1609339b441f30ae2bafeeaf11854), uint256(0x2fbe3dfdb724feaf1c8c3280239858d79cc3d88259a54bc5b5661dcfec1f9f96)], [uint256(0x0dd59e817de235cf12ff054ad9687fdce3d6581b46c696c16c88e616692b30d4), uint256(0x297253acee7d80745dadceeedb432147beec69edd8dca470c61737e617ef2c06)]);
        vk.gamma = Pairing.G2Point([uint256(0x127504dae162a4989f084da7f404d37307ca830daa7eb1711d654149e9d6809c), uint256(0x1b0c582cfb4731a932791f5fe28d54485d609c7024bffcf1159cdde9f1e57a1d)], [uint256(0x207df83d1ba5167508ef6cef1822061dbc21fd4eb09db634fe9d8dfdef3df3f5), uint256(0x2bcba9569d3e91632e48a8e721a58f6bc8c35621dd98f2db23ab93dcb25a3aa6)]);
        vk.delta = Pairing.G2Point([uint256(0x1cf7403b58f737d00ba0772bbd1908e130f72f6440b2f82f24a3dcaf6e7e9757), uint256(0x1e52e0f04bc50567f52cd0f4217afb20ffe0aecd1e30071424b6675ea7530307)], [uint256(0x2c956838d1842764c9da29a072d8760b8f2835f22c81103808b4c244a9fd0681), uint256(0x205031660df396b13a8a19ad1088c7d553c379fd231cc841730dfed04c708e83)]);
        vk.gamma_abc = new Pairing.G1Point[](133);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2cd72a2bf67bcf195decaf6060d5dfdc97bce5a7329ecd17b15e9d8c0781c412), uint256(0x11d6897937d603e1cc34f311d9df3da784772110f0f3c503483dd3ed051bf8b1));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x22884a6a4791fec5cac7048ee4c13f0fc28d431a59745ba415f93adb4777ff34), uint256(0x00c249490bbdf1ae96edde633da2d31c8d09e0365bbd1a1ce55055674ef819b6));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x00af71f39b837256ac7c0f2d170d4ff2fa74cd5221405b3c009abdd69c1df92d), uint256(0x279b4d215f032b766ef1202a1d8a85e28ce5198d5921f98d973288c14f283baa));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x09aa55e3a91dfaa8d94e6d8f04550f3f19d5ec5055dea796cbc044449cffa04a), uint256(0x1de2a6290fd84c0836ba4ff6b5026876f90a74c5a1ffcc6ac676384958ac42dd));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x06558d0dd4d5cc1d0520a95f8a5323a243a3bc878d1b4803cf3736f1049c8a35), uint256(0x21088e8317a42c3071cf764aa4f9d4b04fd50bb6934059c36e80c3e0c9cfa660));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x15619111f0f5b1ec266ef9825443a1247519b5cc8a6481013ba7c90abaebd34a), uint256(0x208bd3f4fb52e84e64952dd73a98f4f2360bcfa6d7e7ffb5aef6091d34a3722d));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x078a02cb1617a0523cdc58b692b14ce028aa021b7843f599680af79b5e075927), uint256(0x1c046302b16b4101759fbc5d7b6d30d415f9750a15798c0d900eb59ba3a377a8));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1eccdcc5c7a99e8d913405d5361b4a737d29c7177ed3825acf616d9ecf3f4598), uint256(0x0bc4436a530bb96d9eab80e8151b6c767c2dbaeca3155ad26d74e83a3a4c8547));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x19619a63c74d7e3b7a4a0277b3346893a757f4b2fc9ee62a1616489e7039a355), uint256(0x2ab78fd55ec383fc89451755fa898272974e44057ab3c204c4001f71f3046ba6));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x10f837d180b44a384b488206e404e685077477f83cc9dfe047e1d1fa405927f3), uint256(0x257f00ea86bf4d0ece2c6e9bad3a90356a525a0d6fe46369deb08a149d6ced1c));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x25d54e807c9dd22a5f8fc0a28e2341c4deb7f327a599fae8b1ec2b140e665b3a), uint256(0x16a8fa675179e193933dd818c690cc9edb583404fb00c8bd5ae8aad808645fee));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2e10b87aea922f098875a582b4819c72be0ba13331e31763e926f0bbe3c89951), uint256(0x2addb531f34dcb0e35ce46b551b98cce354e3a5a7abd31423463ec9b1feb57d9));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x00843f3423f605a40bb6cb272741bbd3001b3ba57423d38d09626139594edfb8), uint256(0x2a6e9e7ff810b4f4c8fbf4b04211aaaa2c71c36290973890050f5d9736e196bb));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1b53a7e3545ebc477ba1de2e1fe738d2dd80247423ba2907803b4569eeafffbf), uint256(0x19b66637a8e850873cf2ab31996b6c3ed4716f5490d6ee5ff9cf2be8d8d3a55d));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x0d10717e31f24c448ca0fad8df16d14d265e2e5d3d72c338f6fe9dcd53943048), uint256(0x15cb646648f27678c76ba20ae28e9eff32b6bca36af21ac493783a41d0ff2a38));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x1c38d59705b619438c35fb1eea1a094478f6b06dfad3c833535c6bc0468c8a2b), uint256(0x0e2a98071f5cfa102e4854c1a9c3a7422d928c292746890fdbbf3385b4ff172d));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x22e460ba08a9a594fa910cbd917a44711063fd7edaa858f234a4a70531b1f313), uint256(0x1cf2786e34765dd79f90ef2638541e2dfe970e55807ad2c48fa588403bee4852));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x1c4a57af8d33030463cb341aefbfe2b988a04d4264281ff8c010147ed6ec247c), uint256(0x29b7bd55db371db21caca8b6926b8ff7cec00a0468d0919a9520055b2ae4ebe9));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x1f60259c41e4ef2e138c01ec5ba1fe4a0e4891287195c1b8b5ece67253451425), uint256(0x0ddb8e359c38c0848f2cdb3229f1fd46557d6ff564dcabc43dd8db5196058dbf));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x2d32372187727149c0defe18240dc61f9706eb3cfaa840727c46d2f3c29ba6c1), uint256(0x21bb4ead774be7c1452f4f8348f146dc974a1e1c5468c71df1262a43d97282a8));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x0ce36f6b08cb9e3af9949295dcf1851f1077502e3d87a80ab64c3beb14dd1cbe), uint256(0x2e5222578e1b8bb4bf6361e316b3bac5783c16a2d363a8ec343dcb5355c14c6b));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x0db0e9eddcc9acb1ce2b8086c1456903dbd8bd70b8982de6225a8e95a61f6ec3), uint256(0x0cba4baebf199c8aac37da7dd10b94c59d41bed4f6e16e7c86b1e567d79b90ee));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x303065440f0dfcf5ecae96f920c8b502e2f28a6d36b163aed994d2f31d29b6cd), uint256(0x2b4625f44c82b43ee7223aabe0321bcfb7491582ea68ed4476a7ab48da02ed56));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x0228e8f3c7b753f5dc8678d9e21c945ccd5a90254aee3f8f90c32c7993991cb1), uint256(0x2b136a930a243a8ad62d158d6149e7766c938d3aadcccea7eedc20cd1e8a31d5));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x1582179d7bbb610986064a96fb4c829caddbe44728e3aa9f2d2a6c13a0657eda), uint256(0x0753d39604ced74dbc0bdaa2d70b887011b9ac796cb75b7f2c09441675333b11));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1cface24cac942c9aa51960f6a98f612ae46c4a95e1498dff38c0219233a5dae), uint256(0x18ade3e800a119c05db39b3081ebb902d7feb882a5997e8ef636f1420d3c6917));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x1b9ec24dab142bc379026b42f16ef7809896c1b1adefa7589832897409d7d3ce), uint256(0x1747470d7aab1efe2ea9b230a50f78a37f9009ffe3333ac4bcbe61763935efaf));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x0e5116b49c572b91d8eae565656c912ac0dea7c8332774459949f09efa59820a), uint256(0x27a65cbcac49eba55a688022a8614a03f07d46129e6a80e87f618ff91897090c));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x03f1e54c9f8c6ea095fba1ad72cf5c6341e7fa01a12a28a1c3bc9332fc60f0d5), uint256(0x146f7426ee42be21231333bd56b942f7947d48ed2ecab1232771a0bd8312040e));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x043bc9762efad236d166779221f6318a12c03c6a3db83efda93363e5e0131128), uint256(0x1e87a9a2ab0a67ab6b2e5f965304fc41510c36c8ccb8bac6bdb165d4d2cbf246));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x1972968d8ad3d8bca35ebd0b62bbf3a98e6e4f85dacfb456f8b2703fdebf1405), uint256(0x1c23cfe21ff99b15fa2538db1db031a3b12455ac6bd2d04d087feba9b412183d));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x2c98694a59a481c6a8459ef1e9417e1eef8bb8b4282b9b5104c82a32b62e0d25), uint256(0x2cdd7899fffe03cf538d0f76ad4d3cf4d3516ddb44c2da3dfb22565c3e5d6e0a));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x0fcc7b54811cc78b25e231dbe27151e82b3b3872a4d5cd2eca11e713fedca86c), uint256(0x29b733f9e945ccac85014c18f3a369fe1f3536b07cb8781e7bdabd1b242c042e));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x21ae2d31bf9ea2b5c5bd8af7af92c4b83fcb195c4384e35e7ae40e35ed73099f), uint256(0x2b9a1e9d91473ac94d4d86ed4bb251bed270ce508574fbfb3405b78e5ff1b6bc));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x0c8499d521e0abc725828a456461dc6ab1f26edce64b43926147dcc4c26dd028), uint256(0x279abddef4b07e236afe97dda0f8436e2453c2065babcf73ca8f3d02c416034a));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x26f38eeed352ffd81f565f51dbc59b6cd104a7cf0af0231ee28be453572952cb), uint256(0x2e40bc181efad39babffa3b0edf98f456f8373f4f79309af186a8466845d005f));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x11ed0934e02bc6ecaeae0e9d1f5e73aec9b4a5dbb858a8e8383f5444a9908c2b), uint256(0x2b072888e7e1bd4574e6f98a68c59afdefcd30f94a321bf02ad2b2c53b5ede16));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x299ac734d5b0cf9557f903ca511e01f5afef2c2dc92bc91a38e641cebd5193a9), uint256(0x29dd5d6d427e178e10933499874e6a0ac954b13e3242aebbcc3db6a4816450c6));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x303f957588d71928869b7d9c8eb26595fb9261f4d275c453efecfca6f7fdd641), uint256(0x1ac3a1da6212ab2b6901f5a1967cb075425e4bbba5bda194eaa0a1d7ef8cc45b));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x2ab426c49058a2049d0bda662f71044b34cdba2fd97b6e02f34295b89fac3b0e), uint256(0x2be8c868c55055d670c1399fa841f98862a11f1aea8ee976e3a021d746d69ce9));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x2d48c8e46fe08a6a9cb3d75908586c7d2f0647ecca82eb8e02bb50ad5e1672a4), uint256(0x191e8e91a33f4c5d00d1a25d6d8e9161d831b7fb99a06f1c168a3d5acdf5769b));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x13cb57ae766105f3b6608327a62d94d762de9b14a5af39913aaf17795030023d), uint256(0x1544f1dd423eb8a79536fb0e820121f31cc7f16b0b8495e49eed87c141e87668));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x18e7a144ac6c3f70cf4d52bef731371ed2b836d5ae9b3aadca1e9fe5feb77d08), uint256(0x24859c69254e2135c08437d2d0554ca5ec7f52ae0741539d47953b345bf99d34));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x22fb5fcc5f3140a21eda7639414e795824d00ec07876c43b0f4309f05a2fc001), uint256(0x05ea3126b41b389ad50e96930109824cf4eaae3d2b3fcf73eb07f1d1190efc00));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x01238706fb4a56c9b9644a8fa8658ba4dd36026551322c432bd880c00d6545c0), uint256(0x1e2c00f52daf6fcf1be03b57b82fa8751f1d9183f144c6e14c0b2cb02d4bb4cb));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x10e655cefd93fd8ef5e98cca884c94bb876f56838b6d564eda79096545122542), uint256(0x187125559609843ea894051cf5f746d2bea5894a19ae0ec8bb359b6017c945f8));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x03ea24ffd917b39adc4860820ce6ae76260ea402c6fb91ce58a60bb4ecadd1b7), uint256(0x16369200b4ec287a0724f329948d3d5844de254d2bd9a4e5e3cbdd58326bd177));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x04e197cae5a9ff447a921b056c378b90315dc91c723d5ba929ab6e23afa37490), uint256(0x0deacef630c290d2550c961a49ea12ac2b23b0e1a9077c557f63b6dc965e5251));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x078dfc94b86b3fd26fd148885f2b7c202bb9ba010010522d17d449bb10baee2d), uint256(0x1391be37ce4265d9bb572f1ec68a7fff09f7d60bf1ba443e89a60b8f62d50c8f));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x12ad317c8168660ad920d773f67c8716ad4061d7e714222cd7e876e791838288), uint256(0x06a3770ec7872baa7b950b02f8f0ae239a79d820861ee0dfb25fdb1ce5556e94));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x30170d82f829b3d5c6108a1fc8bbf3020a3cfca9734899b5ac586368807fcdaf), uint256(0x2995c0567aa1978b5f34c5d6a4da1c54ac260368243516a70b64e0ab1c1e2305));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x2324a7e9e98741c9151a0f268e93d08c523e46e8aa1e08071920f8826e22f806), uint256(0x0a519fdcfa205788c0d03ffa71e0dcecdc0fe7b976dd042533eda15309e166d0));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x260a1f138cc3aec17c1092b381bf3b34b3bb1903033fc599282b72d6a88c8e57), uint256(0x2172f0272e8f11591f6be7339b0b5a54b016ab487bbda22d63f8d8fa2a8a706b));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x01cef4ab817d1df45bd041d40a1dc085debb3ac825a0b8572b9241148c6c27c3), uint256(0x085c0a33ae0eceb88f8ba2ada5ca54eaab64a898070e8632ca54e6bc745e1826));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x075737ae20f5acb791259e372df6ed71770d6e04430cd2ca3b83d3f263097bef), uint256(0x1c3fc5dc3140d06d11ceb79e678eab152d8b6b79e8c305af8c88bac75599e259));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x13f686b9094d0bcb99fb6ff4e0b21acc02d8adcf6aec1f538e7a4169cd79ef0c), uint256(0x253199a0d62b7ec000f9a52c0e5f08f2a1687fd551a8a9df10f367fa536dec65));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x02b95e1017a466334d23a9e1579170d8f4b7921cbfe996b66d553a58e38371ef), uint256(0x1a31d44fc4de774b2b37e0a816baa6aec7fa559a51521081cf1c39aa24febfca));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x144d0ec8ba042e9eaae133d45853e664827d75e9420b28042e3b4fb07312f30f), uint256(0x09678f1fa98adc98613f2ce3e578286633fb2151c3709c6be0a65a119cee85a9));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x0de842a53d9e5b2b1ddf0b5aafce61aae455dca26ee7ebfda5e81b0f5a6a1acb), uint256(0x1343527905f8c4bd5be31b88e8630220cec3bc537cf49cc5a47cf51196be7616));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x185162cf12821079757f29e6bf0b7c1d949690aa9c695bbccc549fead112bfab), uint256(0x1b538e22a14e07faac24ba2b5eeac9c61d7780cae53a58caf17eac8740ac18fd));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x15e8071147728963028f342b220f8a4915c2cc1438dec5fda12d0f404ee8e439), uint256(0x2b2a1fb4c20d1f21ebac3cc44c56dda52d62b9ffd1b83d6ae83e2be64c4fad7b));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x2c468d3da41d7606d2c26f301ccdb9eddcce4e8db6270e313c92b273fd514648), uint256(0x0c4114f7caa6cd36ecdc2b2ac832132bcfdab4a53de087ce36b46f72c737c50e));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x09a2aeb892732a73adc65b97dc6d2dc94cb11c62fca3d54dfdf5a4f4db5a58f4), uint256(0x012ba0f755514ad30b46193e0192c63f8125460e7f7d9b120fe9a8cb764a2da1));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x0f64287025b06c9522062a283d771e2b88953159a8f4a7a426580f4489889f36), uint256(0x1f216a3feef3af1ddc5bbc93479502d4d29a1c8f3b0043318709ecd55b1840fb));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x0377be27d2dee1d378758a3c45f2860af15d844eae0e905c0f5a28ff9d2de71c), uint256(0x0c74d56433dbb361e8bad3d355711707794c2e7cc57da1cfe48bdd96fd50bd86));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x18a636f7e8ef122adcb4e68086f1e1be16aeb97b611fb7c7bfb305460955efc8), uint256(0x2bc4b81e045ae67bf2fee6f56171ce3d87491840e9d650f7746568a2eadb0e37));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x152bb1d8c6e2fa4ba16158bc675d96a6ce8442ab175e03e79950d84981b7c6e2), uint256(0x1149828119065e1b2b2b1291a70b7b5d40044d51a9615c6204d9d0abb97864c9));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x0549ce7e8a7f8b388b11dd83cb27f5eab7f63ec3a7ce20f25e20127eb8c2c5b8), uint256(0x25ff5d3640db8edd14be211ee8a2ad2709696818d047a41ca16a733380672693));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x1085f74f8ba24ab530eb690a1601cf064c7f6f01c092b9ba7b9aeeb406988483), uint256(0x0feae8f21fafad2a9f64609075901fd2f1f8ea6bccfbfd97371f679af46f67bd));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x185bfaf3dae58fdb2ea8da0191a29b7d1ce10ec2428a99f10d6ebe7e25881954), uint256(0x29018757e2e925d6d2f89d2cc1afbb4decd9c9c005588cd0fac80c46b9b0bb1c));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x12579983b511ddf0b167ce0eed357ab3d2220ba5f007d685eda73e782dfb8348), uint256(0x1a6289d996adfab2fa423ed531903fc90338f6b9bbd4b5dbd8d944db8988901d));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x11a7d02c68d088a70c4c320c2a17cc8e46b85251d96a47b81c910a709714ca09), uint256(0x14f647c6b7fddfa8380ae4a6d4f71bf5dccd549fcf82278d52caf560015fb134));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x21c3edff29343859bf6ee3a0b4f5abe23da6b462698c68324abc301fe56b700b), uint256(0x12d5e9ee380616abcd3008c456d169e0e9e02bd771c001fbc017aa0cacf038d0));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x0ec32e80005f7c787def0e601f5a3b8ff9b0547599cbfb3c5da89b8e41546443), uint256(0x2be412efd9617f32e8b4dc84541b648d4c7688cd3b52bcd3ab0fee102c5aa024));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x2b204ad3725c18fb2ea33f97a9e4fa4fc69d5c08a53a14decdb0d6c851658216), uint256(0x25dfc40f744fa638ad9612bcd363feccc29515211da46b8668c994556eb22efd));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x13369f0f6c8ff0c072746bf1e24419b59d79aef31f10c07b0f06cd4abf3727ae), uint256(0x277b4da25a407257cbe9f37b853dad2cc5026fcb0e159fccac51d77906444b25));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x2e63e782d4e3fefbf115f4f1fee25f7a622ffcf13b08a049702848576fa54420), uint256(0x28dcf16fff3a45cb55374afa036963dff760b5ce51ea6f4a1a31bf424280b584));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x2a1017b0f1c2466a435e5b8e9aeec2983d4b723fc69edd5fa99ca43ebe69aef0), uint256(0x1ec72b23343ccec3321057296bda98bf895d4799008652b1b92d95c32218f34e));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x2b36036c8c65855936e646c5dea45660205152b007db84ee932acb1457949998), uint256(0x0acf2234af5385fa26ea7a07185b298d97c410db6ae89e196ddc5cb3f43f3be5));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x1c1ac3fa059f6264937a60d95c9434cf27e6e29e83b8ca3afb363966352ac308), uint256(0x13ece77f6a92ccbb8964ccc49bebd34a421c2de15283f02853a07b07e732fe61));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x126795398b364b09e8afc4a432e5cdcbda3d872672e89b73783632b23b9e7371), uint256(0x0453e45e4a6423f35684e92280f59d5ac8b889ba095fea2b1ddd79d24604e6fd));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x2ac61c6110d7ee1a766c4bda8b0fae59ddcf0bfb8b2a621a1629321fc3123ac9), uint256(0x2eeb1a424a55ce21bec753cd1f92b3c087eab98c2af8b735935e51244ceb7092));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x16bfb27d75a37f4fbbffa30debb3965c69fe74cb9af8e94e3b57f5651393a4d8), uint256(0x0ff1f89aa021f60a27cbc20071b04eca8679f7f950971634601702cda3542676));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x09d44ebf23bef4144d3a6f9aefcbfa3901b0420ae553e47e2bfb0ecff00a41c1), uint256(0x277bb36a435120d23ff92b6fb33b208cba79dca15dfd0bf068839a68ea179502));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x166b3f4f982efa88f524ee8a7701d420d031837614f2c85f201b09bab307c526), uint256(0x09547dec4e6a9641c40518cdb15a2e4021afce5feaa7a9278337d94f2ef265cf));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x2c67f0d6bc0b3d81a15dc23d14d04b961e423c0e7aab1e6a415a105a1be072e3), uint256(0x2102cd868a80261aeb8514caf7e5539d2e8ee3a3edd0a5dc21e3343d33d352d3));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x1f20cfc0f2f47d7c9db942459cb37f8f565f3a668ef906d207b349d3464197ca), uint256(0x1f1ba797d8ced559348524ec67843a5add75ffac36a6eaaf02db6bda982252a9));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x06f4bce27d6bad0ea0f95cd0c89b498f52dc38646ce1cf8765c7c62b2cfb8102), uint256(0x163fc40bfe04a57ab82e1481669281106ccc291e6477a9b2e315e99fff2c3c95));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x1ada1c07b5159b8dd1e34881d255778794646f3b517eb36ab2dffaebf9f17e6b), uint256(0x1d8fdab3d0218c5bd1e7cb9751c6225749d27030640d47b41a75f6da49bfdc38));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x145001064849fdc10d7d089f845e61991d94e4734cb93a1ecad0920bc285a796), uint256(0x04a8cb0bbade2d7d3a171f065c1c91c73686ced7bfdee52365e71e79e2dad51b));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x04d8abf06a61d4287eb131840be4046d34a75493d938522f0ac6ba5b76999c68), uint256(0x013e89b6bb78becb4c4cfacd1100796a2c9a7833a8621c62c9914dc56ec771af));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x06d84440ff2b7fa1c0224ce2babb8e1b68b941f37cc9ad26fc36911433cc11af), uint256(0x197216a7762cfd32182d0e391a8bccaf6bd0b18b75cc3a065012d95550151ff0));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x0e061b541aa0a87132f198981e17e7d96f66d7547a48829349319f532f0712e3), uint256(0x067d0d43e2de153d1cb821fd4716f6289c237e00b3a868e467a96e9913468acc));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x1e867fd207ff93adb9c9cf0134ada7af0d52dad9eea8014c2c3ad47e6c91e9b0), uint256(0x14162f1689e9739d233b99ce9b742538b2955f86d4bcc075866c4ab64f6008c6));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x0c35a4d18094b20a9c245791f8876ecc9d37de6553058f2aafdb37edf3c00133), uint256(0x294d858c8f9df73949eabb302385bf065b1d7652eace10b29893e7abd856d81b));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x111f172f40c5d9726eaf80a7c0233ec4b4c6d1f8e285826f820305af4794cb0f), uint256(0x1e91fad9ba72bec86e1146d8ca2a864a9c8c020effde9a50c20dee8108eba923));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x1fd2c2043b57086b0cc46b8ef2df18772951f8bda3bde12cfa5db61b7f3d2bef), uint256(0x14f7263489c2130dae61ec0e003945020ea1aae0134abc48ecb2a8b9148b21d1));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x2246a5a3a734b5a612f22fb356d5c8c24d8ee2b1fa2b42f35bf9273455986315), uint256(0x256ba36c2ab5e31098e3891e33f1cff3b5638a837cba06d770c1d908aaf4fd28));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x0ab8c9e0d7d61d0e18da5505817341cf46b0f3af2c072931a72e2e95bd7ca06b), uint256(0x1d6bd69e72748496a3bcbd930b7a0b2409018141959ea7fa52a3008db6d88a8b));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x1de538ed7f19c01ad84df29f439495a907e6c32a548f9876e2cad4b895e1ebea), uint256(0x07d0962df8fd079f0f561b16c2438bfc7c3a8a58e2a1820f3470dcb028e82173));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x2c940d1e519ed02ac5b4f76cd8dc9b7e7a7144cbf0a2f13e3459b6f43b54a61b), uint256(0x0058b2abd7c4cd76ca479ea9d77815622e9d0ceded95a09ba4231b056101c345));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x1a07bc21b7d463786c2c31c762fecf468acfd09d57ee7ee7b2bcc00eb2eedd4e), uint256(0x25b7a32ef27d012b3f8f4c981e7c2c9a86fa579af750600df7ed47f9423e9903));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x2e0ce468378f6d1db4617a6c219e1b4b5656c5c80dcd69a819b19204e0ceaa33), uint256(0x17a967bd6b518534f822e293e0d3eeecdb803e80d03a9ecf35c04341ce84159b));
        vk.gamma_abc[103] = Pairing.G1Point(uint256(0x1d778ebf7b5d4fdbd0740ab2125d3d9b027982f32620940bcfd72ac380bde09d), uint256(0x17e7ab2ac0f1863c9f6b21f557ff476ae88b38389a08ee52f43ffafcbe9784b3));
        vk.gamma_abc[104] = Pairing.G1Point(uint256(0x0b09d60dbe0fa7911882c27df139cb52b771bfeba6d5adb0a0cfd9cc71105b4e), uint256(0x13344d1a46f80949fa3c21a203a09e43ff5f91118e0a9ad70dbb4c2222401e0f));
        vk.gamma_abc[105] = Pairing.G1Point(uint256(0x0ff7ac1c2165893432e38b3a6bd2e05e14e90f285028f69220c72a8d2803ac4c), uint256(0x0826c05986144aec7bfbffd3ec2e46bbd532463dc74cee9d1272e899cf17523e));
        vk.gamma_abc[106] = Pairing.G1Point(uint256(0x28fb8e972f117624462e87006fd27994b749666338c372e4fe55b354d6117ee9), uint256(0x121cdfbb781f0f1fa2d188a7dbb5993880b0b0db550f6fcd619d22f149716b73));
        vk.gamma_abc[107] = Pairing.G1Point(uint256(0x02b7a7e70a2d9ab9e917e71ba688928dcc6d1d454fcbeae7bc04e5a99c7503c0), uint256(0x28d36b87342395f802d7fff26390f83168b6adfd4f24b1144865e23bdc10be98));
        vk.gamma_abc[108] = Pairing.G1Point(uint256(0x0b199f3ee48eecb32f0181c44e6316b018ff09db9911debe62e692a1d3fdeead), uint256(0x1dcbef3de63ddb3003b4ce078542e91d6226127a0760374ec26db06d87a4232f));
        vk.gamma_abc[109] = Pairing.G1Point(uint256(0x1fc06f76e59a2db20bffb3ae07d3bcfdeefe21a16bec12f624e6fe18f43ebebd), uint256(0x21bf0a60341011470d7802bdec3ef664db009fe22d28fcb6a1bd67f867074a20));
        vk.gamma_abc[110] = Pairing.G1Point(uint256(0x24251c32363a860da445bc9de76ecf570c5de65fe8b94c131806adb8f1c2692a), uint256(0x0dfacb07cdd26440b759368629b9d40edc3605e20635b5968a0757fff64bc1a0));
        vk.gamma_abc[111] = Pairing.G1Point(uint256(0x1b3b7b9742a33f4a6f72d9ee1917a6b816de15de36e5a80c0775a3ce5f9c64c9), uint256(0x0ddc5a3bda6e2eddafb75ffbb7a0b9a733df099e1e7e796f25b49adcc470c65c));
        vk.gamma_abc[112] = Pairing.G1Point(uint256(0x195c2f16a6e590a3faf4e24ab38ce040e3c05a72ac0311eee5018665b44c6364), uint256(0x192883a75cbd1fe7d48ad320ff601e3395b9ca9589c9f95fd861b61fa220ac81));
        vk.gamma_abc[113] = Pairing.G1Point(uint256(0x0383434ff3cc3c9b8df08623226150b0731c2244318227a0f7b678fc7b7ad6c6), uint256(0x0b16b3962ebb0a984608e7a9ba82a8c8dc9f270d30bc5d0a8dc2b63d7b0c2d50));
        vk.gamma_abc[114] = Pairing.G1Point(uint256(0x00893215a3eb5b9e75c407564bbcfd508d82473dcad32e12bec01b3cb33abec9), uint256(0x29bc7a191aeb4f3de5945ce3c2bf96c15982e585ef5df052a25c21a00724ac71));
        vk.gamma_abc[115] = Pairing.G1Point(uint256(0x2f1441b705b5ced0f2a35311163eaba945df1cc37fc317afbc725c3441193f3f), uint256(0x25a7906c4051e087524c39836290062041156dfd9adba53d7e0f65c55d9c2855));
        vk.gamma_abc[116] = Pairing.G1Point(uint256(0x103d8c19eccaf69edda563933b8805630ee0342e876aa7d498603b35fb3d9714), uint256(0x2a15d5fa7e9db9f87d9f8329dc50915697c4ef3c8d6da8846de5605940cf120d));
        vk.gamma_abc[117] = Pairing.G1Point(uint256(0x2160090a00570c5105679c1d5608c83f04e95e257a8b3fa5e5617a1b49cf336f), uint256(0x2a56a17156046f95010b787271e6776d7ef5c3049defd94a9e1bdaf55a2f0f57));
        vk.gamma_abc[118] = Pairing.G1Point(uint256(0x2796e88dd16d969fad9c9bca3ef239596f5055a1a98a54045168bba151f85d3d), uint256(0x12feadbe54b5fa61a782c787a8f5acc6aa47f72300761780527ccc8538370847));
        vk.gamma_abc[119] = Pairing.G1Point(uint256(0x062a980f2f8d3c43462a807818627abd1cd469223e5c4dabb5dde52b9a31dc1d), uint256(0x1a212e0677c5d01be2cb8a91d0e98513ef785bcfc74b85da65ead90407419f09));
        vk.gamma_abc[120] = Pairing.G1Point(uint256(0x1c923be7277df3b2fdf2a753d3b4eda18b479defe430c7208fd6a96e5bc73162), uint256(0x146d37673f4127df18daaa9f56f3cd04de4022f7c4cf1a5e78c7bc882d61a36d));
        vk.gamma_abc[121] = Pairing.G1Point(uint256(0x2d7b31a05155f09edba7550bda760e0d605aaaf9f2d28b685485fcc541afdf51), uint256(0x14e0337def79247b98dd0dbd0d5d262a43231b0566a234585f6005cb5f526176));
        vk.gamma_abc[122] = Pairing.G1Point(uint256(0x0bf0e7ba557e532417a18b1faf932fdeab79edb9c6ae4fb5116c2c8a2b11ecf4), uint256(0x2fd99d88ea13592b7257e70c1337bef24fd54cb770bc43b7cf1b92e58e6059a4));
        vk.gamma_abc[123] = Pairing.G1Point(uint256(0x2ae02e4423b9cb6d007d9b08a01258dd8e688e1f66642f0fec02d27b05260432), uint256(0x2e517582f7726aa083e0935ba79bc4832b61e0f462636dd3ae30d18374c72f51));
        vk.gamma_abc[124] = Pairing.G1Point(uint256(0x1c44cab9b3dcc0fa2285a7d86745142a6bf066ec2a4c5509dab3d797aca68e74), uint256(0x0ed01afd23373c54a74f6d579c9f3e0343eeddad385f37b622f76306fdd63828));
        vk.gamma_abc[125] = Pairing.G1Point(uint256(0x11a08b8e9e452fb13eac7e907eef3f41151177233b680913b9374c7a25e438e7), uint256(0x251f3002e1ba754e2e2bc4a1f300304ad405e51f5090f88254113b293a5d0620));
        vk.gamma_abc[126] = Pairing.G1Point(uint256(0x1201799c8a7c30c31f6e892cae84cbaf7fcbaee52ad6a954d9fc112dbed30376), uint256(0x2bc148b578e20d0b32bbaf0065192adfb3de0cd93a5717369545264796687dd3));
        vk.gamma_abc[127] = Pairing.G1Point(uint256(0x2442a432955bf8cf03acb05e50c1762a2bf749f76929fd94b8bd2882bca74b7d), uint256(0x12daf39f7fd91573f463c43a80f2599b8f5365b2d5e26481aa2b360412b94d99));
        vk.gamma_abc[128] = Pairing.G1Point(uint256(0x2fbaa7627040a7c5c948b76eee287d421b0efa804cf05f197f59cd55ce84859b), uint256(0x2947aeac71042444cafced299926672e7e49da32b72035d3e9d73d3f80e6c900));
        vk.gamma_abc[129] = Pairing.G1Point(uint256(0x06db98afda893f4f3f3087d2859867e14456d86cc2d1c1979624a817f70841b4), uint256(0x00cbe2727e7d072b0907bfd76279784a1c3b523a05ced0c493e1ccd7057c7c3d));
        vk.gamma_abc[130] = Pairing.G1Point(uint256(0x19810980b5e4cd4c78a4bf30f1de9ecc5d8e355914b88d091a343ad114faed39), uint256(0x0645acd8ba30bc25d9edd584966f691c946237e2440c3cc2e98138e9bc8a0c51));
        vk.gamma_abc[131] = Pairing.G1Point(uint256(0x2f4aff21f0538fe16f5b6f722136c0964113b1f2bda6f78e48fc7847c4f577fc), uint256(0x1f9b245aff5710eb444a65f5bd0b5c03f61dffcf83328e86699398e7fd5e5a4a));
        vk.gamma_abc[132] = Pairing.G1Point(uint256(0x0a498f75ea3e30616bf8ced7ed44486438beab01d78ff228d604a7e35dca8628), uint256(0x00467a1c717e266a1c2b85ca1be7b84f9ef82fb25c14d9d2e42afd77ec2e2452));
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
            uint[132] memory input
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
