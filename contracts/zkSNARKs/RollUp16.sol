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
        vk.a = Pairing.G1Point(uint256(0x0e234bd4987ee794b5c80de2746b1583a0e97f5ee09db94bffd84d264a85289f), uint256(0x12d41314d5179c7e02d640dfd3d62d2787b26d0912a7a8d9578bad4e0c8091b6));
        vk.b = Pairing.G2Point([uint256(0x293645cb1d4409fd4ab9772d0d85f88bfe2b27d575d0d88393766ec64cac28f4), uint256(0x24856908ee55307a91024a492c85ec775fdb7f6178296842af8887c90f27a930)], [uint256(0x1754372f9e938c6b6856f788c51d72fcad71b216d67f6a73c96938a5b1a792b7), uint256(0x06d1aecd170d682f49d4643deb481de99c6a54896c1a92cb54ec7875ca31d185)]);
        vk.gamma = Pairing.G2Point([uint256(0x2db392c4599eebaa9f2503fd26999ef5016466b2397d20523321b4eb787413ae), uint256(0x0de6dc4d2dcb8f3a9fb5205ad80c9e38bace078b837bae18b3186c7de1f51ba0)], [uint256(0x1b7094dadc72ce2cfea72b0681993bc708fc4cd794490ffafe8d3cb7f56cc8ab), uint256(0x0348a167bec63fc2e6270f43e01e64547f5371051970f7ab909102106bc4d093)]);
        vk.delta = Pairing.G2Point([uint256(0x2b21648e1f5aa3f97587624ebd8051a741886a68282c32f40165432bfcb79d99), uint256(0x2112eeecb4f5a7723561cf64ea07b23533aea250e8abe2918e67afe3d21e44f7)], [uint256(0x295d7c6d60a865326de160a8dd61a2a200806122a9822b8872c2c39d1fa20e0d), uint256(0x113098d86589ff81af6cefbcf06100512354b3440b446a975c1dc8943487a9e2)]);
        vk.gamma_abc = new Pairing.G1Point[](37);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1b988e93ea26f36b26803be8bb6f37ccd1798e993fc639b214cd9befd6c7dbec), uint256(0x2e2fbefdddaf4cbec5d6b109cd8ba8634c97bc20f03abcfae188a581c79c5b18));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0f5496b56bfa320518ecd881c15a3fbb156fad2db235c9b68496961fd622c832), uint256(0x1d1a057342a1a7a48b159ec31a2d9b215195e06f82759671f5aedad9a428dea0));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2404da693f31aa02786fa920d2271383bbacb5af7f7b4d05444eb480cfae7983), uint256(0x19d7ef951030c19dc197ef8d91f0239ca64fa2d1920fe75a52857413d47bf2e1));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x099d77bbcb03d1afd9d496c4622aa191976026c5fde4da6b4f005a0b3126285a), uint256(0x1ea006d4127ab70d8939392cf51ae63bf988eecd44c40c5eab6e51483255a2ae));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1fc854d6f59042af0f9ef9c0abe578deb45e2b9243c7df824afe581c0c8c6674), uint256(0x1f26a2e1a9f42a9c679f40178ab7dbe7be1bbc2500569a221c76e4af0bc924db));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x24803914c28627328af6dc7a8e5a9190f7758e272e2349286bed93bd5bde5c31), uint256(0x07f6c1905d980a49b0260f44ffc5758540ac29609e0361153f5f573e1498c8b4));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x12c80011f5a7d26feaa887bbd99025028268f90c89dd3282daa67f29cb2a674c), uint256(0x05088d3925a2fead659432f654c49dec0e5da3f8f45a714c79b019f184abb19c));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1b2e5d181fd4dea7adebc0d45625b9acf07dc4dbda6e5ea6707424c6b3adcc28), uint256(0x094a1e722320b59bc3452b874f6ef1be510381efeb7f1e9131952e4e04693d28));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x054ec9d4d7466f6862d9b7a2d0de556b65f926b9903cbdae128c3acbe0395910), uint256(0x131ffcdaac03c3263ef0221ae2b5cf563c1e1f7d3617dcf4abfb2cda2d644eb3));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1ce1838e09f6b09142796e33a4279903a3088eb60f7118926f95586a8905d5b1), uint256(0x190073ee68a6b0c76a09085ae9b8e0bd183194919d74dd0d1e91ce27ac57f15a));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2a2aafb0400793f4620d1ce88acf5ac3a0b760f554e5396cb5b34d6c327f54e3), uint256(0x2460c9debcf89e7b9ef99c3ab1a0b44ec2d58b422d1fd39c1ced464d928c488d));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x02a435ed7f9ed78c45395e3692a483e5caeba9e8610f59ec3f96a34dd7b5a954), uint256(0x04298322c820b5a4d0c6a11ecb0fd9a8a72178698c819511e7d5283cfff6fb9f));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x17c987ae462be47970c63474ab69604ed04ac6f3a1d0a0af4558c353a1862b74), uint256(0x0199349befa98c45c5d8abe5f750767465f781e1f9b3b29e25f1d7bf19d2bc7e));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1c0dc58d170f37bb4c2aa3c720f1238142ecea5f51a18d241c3e92c3e589d581), uint256(0x007babc0ad2fc9505890d1e3bb537fbf07df70e0ce7cbce41bc6f926efa773b8));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1f6a7334907f9e5fa95a51c6761952f177c2ed3454530eb5f7929fc8fabb48ce), uint256(0x015c860f18368cf63bd419d9594b4536e746dccf3033a79303826f378dd481bf));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x0ae12e0275ab8419b7e6c3c736cdfc83a9ed28980d716bfd502775441e476f0e), uint256(0x0832252f8873246755de444d030623f338c5510ee0f929c244eba0ac417bf32f));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x2ccc6700d26334bd9ee9d66ac89d5aae47e8eb427493480a26f46e10f3e2525c), uint256(0x214ce40763c4be92d770bcfb25e059165577c27eb1a9624f7025c0043c862a76));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x07c1f0f5d3875a2ad53d105616a96f557bcc4c906887328df205fc50f1ffac1f), uint256(0x16712cfec48b22e557bf0863d3b618bcc9c17b11cf15c0225998af0996260c8e));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x16f3cfffbd388bc6be83736557bd5eeaa32685e279dc67fb3f09a9de94f27f99), uint256(0x2ad87052a3582df1a24b9fb8a7cfa756825442de766dc606f96ce574ba13067e));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x1a3ca524aba0dc213972765c3c1c80e99232097c1db7e092caf526be7c6ab3bf), uint256(0x19d436b79e313f172e92922e1ed3d0da6385ffb9006337c7b6ddf75376f6a813));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x022fcd92bbeda0eb65075dfa074e78acba05ad98904778c96a60a5d65dbf5342), uint256(0x2b3879e97b0ed4fd1890864b2746d8f28c2707f0b63749659f70e4bfafec8f4b));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x06bf2ad47999751439fdb86f9ba3d1c7da7c8891bae82d654a40203e8034b95f), uint256(0x24c92d9741e6b24e30c26d5a4017886e075d3dc215dae1ea0d7a006e3ff5be55));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x2605d5b3312177ff0ce73eadac79ae7a11fcbe28307595bb8f20d1ac98bf2431), uint256(0x0353176af74cbc647f5c0e936e7f3606569c64f146296cc9a4c11345a7efe331));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x073d0fba93027978273d230df7632fdb1f14c42fe1243d58008dda6d3792026a), uint256(0x044333822c8a916d7d49001ad5a826fe2dc19db49015111c9b97339a18ae90f3));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x21efcbd5bd6e6fc527fcf39f7bd21c9923e9e761db3121d5d69d0a4921e92708), uint256(0x15fe52b97a81cfc7b7cd5d7573c29438d976be99a09da3aa7fa1a1f286fafa2f));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x20fe81599d93c172eecf68a6fab5423d6bd2b5710f628cabeae00d55597150e8), uint256(0x13c7c4154475f78ea32763e5db7df43b8b928b6ad8ebb4902b6c27e56158530b));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x0bc325a1cdbcb3abb8a53e0cb4c178d020644e1a328ceb366e489cd6dbfa8bfd), uint256(0x098e10e9d41f662d240aca572ee57621c2e3260f585176bbc337ad5731aace4c));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x0a469687e7aebbfb3dc5579f96f944bd22bd6cc103451cbf23bba36ceafc6a0e), uint256(0x17aadffe7e12c0f5ce481a515f0a5971dde753db66a44ff1bbe7baa80caa27c3));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x0a6830f4991a0ce6da1fcdc819577f833cab5a726454f718d6a202a53b4e7f4b), uint256(0x0eb8d4b5f86a49f972c8621eb590341765e6f83f7a3035f0cf324f56f953036e));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x0bb98dc0c1f5c5ff638ed9b4246fd44a95fec68c899817ca935ac44f7b0ef378), uint256(0x00fc0ec757c236b8194936969e97b795b27ea857e8353ba10014702ea5b83374));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x080ec1f88c156cdc68e68bc24c8a4f98fc4eb45793fc2841906e16ab777a62fe), uint256(0x0f3a64854d17c70b20139ef33438b2bcea21ac3d274f275d4c0ab499e24eceb5));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x18838445e592641b2999e38b8fbfdc0691504a65566ea231db2edd683b39f42d), uint256(0x2ff6963591e70cf8a5cf4183627bdb5808cea4b78672423f661b75ccb9aa3b1f));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x13b24852ecb49d62d45f4ecc6a0a5d5d5c8d79a137769c99e73546417d4a4783), uint256(0x212b90c9d6d25dd69a1bc92c7f1e69c45fb7205e1a4b993f7720281af9002b72));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x232a4b15c0f528dd7a500c63238355e450b209ef89c408c5c237bb0230d01070), uint256(0x2c4bc762be31b20abd76b37eb2d7bfec80162c0bbd219596470b8332a31462b7));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x0dd24c0250caeb2bf51b1e45543783bb566cd092d05c1d6fa4d39a7003273574), uint256(0x2a0983d15f5ec251731e8dcd6e8c309df10ee054e6eafc51166bb1675a2560e3));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x2a203d5344e32c0e82db4fd2ca048e675fa0d6eddb7a3b93c8e98ae86c1b7b99), uint256(0x100ca0fd169874c8396ad87b4aac569356052e4f8f6b638516c1c828cde9f77f));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x1a9b133fbf76258c4b37c2a8321b873bac3ca1bd1b8cb54eecb0286bcce8aafd), uint256(0x24772f0a74ea155205f2d835ab491ecfb1226a963beff9abe2125600749ebf32));
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
            uint[36] memory input
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
