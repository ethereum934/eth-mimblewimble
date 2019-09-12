pragma solidity >=0.4.21 < 0.6.0;

import "./LibSNARKs.sol";

contract RangeProof {
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
        vk.a = Pairing.G1Point(uint256(0x1ddbac51a6fe431c5aff90a14172e395c656c5ebe46232c3ce4c5cef95e83d4f), uint256(0x2c4fefa045681c370a0f48a5dbe84994cd6115e19c0bf81779d2ddab58b4610b));
        vk.b = Pairing.G2Point([uint256(0x18227a63c19a880e5d883aed18d1216d63c0b39c03360ae4fe536fff2cea6333), uint256(0x0dc0d60adb4dc1465f7968130c5450d0e5ea256895b61c192f7aa1096b5e5cad)], [uint256(0x0f6d748c90139d53c23d96e6721a235ff0b445c58d603681bbb68bb5598fc732), uint256(0x2d6913355857404fd1ff9eed6dd95bf06f6c52077b533a4b993525586df2bf44)]);
        vk.gamma = Pairing.G2Point([uint256(0x22f24ae8e29762a9c170e86d1ac96bf199e608b40bd44e916a0fc42d448688f1), uint256(0x2775dac82fae030f981bfdc2da71a96282967427f62d71e9a32a69b9c8d75184)], [uint256(0x2481347619c7a0ff69ca74ab6265ff0dd2145385146f12ae53a1f2c3d0a2b6ab), uint256(0x1782ab1580f3c2b2af4d3d406aa52021b620731f4dbb00f224077314387b0b77)]);
        vk.delta = Pairing.G2Point([uint256(0x2d2faef37ca90f8a49901c1ff6147f124f3ed38b395614e459023de3b6a924aa), uint256(0x2a1a4aed0d3040e720f441be8314950f87f2107fde550c48895bf9e011cb908f)], [uint256(0x140786c22059057eed6ed94da4e6c34f70cc73f8fdd15985be83889b1a2d3f5f), uint256(0x0dff20a7a51f31100d8eafb553fb3c05a2bdc33abe2203213bb93ecea97dd09a)]);
        vk.gamma_abc = new Pairing.G1Point[](3);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0f3026e93065acf55ac923b640a89d7621f92d6c2783b785f3087fcc1f354467), uint256(0x2effa4a3d8ee20b6edf1ef69e9b22395d2d09a08d00a422ad40df24bcaf6e762));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0bfaa1faebf3e9cc361a572ea2bd4b8e0d4d739621ca250e0e1bd8e02c7bc884), uint256(0x10dcc50985d8f0dc832368132b9b8584fdd767be0265d32e7150523ef2e235c7));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0cee92bd3af7a15ffdd0cdcef874e1ff98031615cbd00f21e56692195beac18f), uint256(0x293d5d26fa1a82d9e32da4356c4d1298089569f4f3d18120616f0f0a14e175d5));
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
            uint[2] memory input
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
