pragma solidity >=0.4.21 < 0.6.0;

import "./LibSNARKs.sol";

contract MimblewimbleProof {
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
        vk.a = Pairing.G1Point(uint256(0x0d1c818a2a89dfa4a495071d49501b54622b39931181fd3e8b09850b5c04ba9e), uint256(0x2cd3118943d101f297c22e1baedd3a4ee8fedd53a12e277fbb82f6bd0cff2519));
        vk.b = Pairing.G2Point([uint256(0x271b53e057532dc0e1d9c6263c39b51097953ed5b585c296954bbb519cbdffd9), uint256(0x0df1a3505426339d449ec7a1ff5e5291c74bebb6feafced46c2697a1f2e52966)], [uint256(0x1468e6b44f2b4615cbb7b2905c3e56e96aa3391871d01825d09c46fb801ac7e4), uint256(0x163343d4b803eaf4cacb967dfdf7833792d1a06b8ed889739bd295aad994ff80)]);
        vk.gamma = Pairing.G2Point([uint256(0x0e4724352ed7a6b7654a33037594a8be295969ef636d878eb374655bf3e2a3a7), uint256(0x2844cba3d1f487a6921481522da6a100add1c97d4a4c772c47184a73af0f48e5)], [uint256(0x01a11252ce952af7957cc62624d3c121a66bc54d05382ad769c668504b5a3000), uint256(0x0a99df9923a7b4d6a91db0c05fab2b57b577b34921466439b09d4b6873999bf1)]);
        vk.delta = Pairing.G2Point([uint256(0x05f01d231e56ef501b58624a1c0383eff7e8e338861382a5790332c4aa1af886), uint256(0x0d0118eb5dbfc71a499b3dd491dca17838f8e5a15c8b567026f677c86739e600)], [uint256(0x1e404b34cc6d53a86ba21ffd6f162ad24c441ea8e010475c4a9d442863c508c2), uint256(0x12f739606029c2280a6bc3fde1515d5628364b27ca0ac2c72bea1a097376ebe1)]);
        vk.gamma_abc = new Pairing.G1Point[](16);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1001a3b0dbd1fd5dbf4ff8f3fdd9e2194754eb84c2a644f910de923b4169db63), uint256(0x06fcfc91438b026075648c493468c08669a58819ca941a6f5872381ab9e06d21));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x20d0de7cf8a837b19b98d526268c4e46a60f33287ca4ccafc3a4dce0a4dba198), uint256(0x180a84efa73c0be384394371b2b7da4ef5867ec55776aa840b3d91f0e6cab00e));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x13f5c7af0c76998fdebc2a4701df2d44390fb78e927b1d7f7dcb970d3da4b816), uint256(0x03a880dead678fd1ea118a5f52c0f47c0fc854101b57c60fe57f3ec3eb66da46));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2635db323883355cddf8a44dbaf0ee8c8fde9a7bf146e15fdb7ac1b0fff5db67), uint256(0x15ad9487e1fe2b18f6d55caa04e7a552792863374a2b82b92d128adf53967ffc));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1e8890a23e1074a6a80183a3d036fb87b87ae6122d9b43922200418895bd63f4), uint256(0x1e4f6f50576a061787597429e74c2f81ab8d1dbcbc1163afbc85d581c12f4c61));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x04cb0ac72bcc812d48c47489d6cd2c5ae5587ff77bfe3264b639341b75e9f24e), uint256(0x11134b8282246fc742c6cdf2ec2204903a631f4973f808198892fe1a89a5f09a));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x233ea56d4dbf54eb56533be5b7e5d1923319c0274b886a1e672112b39bd2fd0b), uint256(0x0d655864eead31e909c444904cd4cf15817300e176c1260a1f05b8ae2d9f19b1));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1a58bfad9e06a1d0985e73a9239705fc61953d4349b6044711e9ba8eed8cf2ea), uint256(0x2ef58f2b8b1d58b735a7dff69867f62f8fe5602c8487ce1cf7f7bd739dd49ae7));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1837b46545d2e81e045a17312a79818e7390bd817c8e0764a71cbfee6c862564), uint256(0x1862151e60e1ad0f304beabadb22f0cdcadae828a552cce718b8779a4e7b67a5));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2c359fb23aa59ef46d3c4dd002d4d52295420b6b3592c861fb838d29edd4c69d), uint256(0x15ba09d90ef991951bc47889c08f8b14c8df50bd0952694d39557fee2cfd056b));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2278e88f9a20271899b6a4a9fb1de9cd749c3f2169af19928d68556e1b8c81cd), uint256(0x22ea8b3cb8690d0b15944260f75834ca4e4a99f8ad17774bbce757833fd42f5e));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x26e2c6e74616c39eae3463bfd67a4f7699d70cf2a00449b454f20b56f7791a86), uint256(0x04693f3665ccb88ff437a44a256fc03a9e339c40424e0372b9c95287a7858ffe));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x147487f574789bc765000497c07f5ecf60bf3e5cdfb8a2f1f9e1d25f5505f099), uint256(0x0ee1813998c57eede1c26155d3ff365fc092c684aede0b2809402fdf34c59ec5));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x252ddd2157886049a88249cf74ed09f01b1796980fd4d988cd87db39a3bc1a0c), uint256(0x0b43f11d215859244155cf8425521b3feca504c26700ace85c93ce6c65a6f55f));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1b760a10a1b72bc9cf3669c6da6cc7036ee1c0b1ee1425f045ea66d1d52dc796), uint256(0x0c65d04e5a13e1030f7313afc385b9d52be87033c8164aec79e1658e7c3592e7));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x034533db36741b3d6c019e9132147ce222518e432e39ee716d5ba225abed0a6a), uint256(0x09f6d7159c9b54e68c560c53e9fd41e9de8593c8c026b9b0eca21d36198a99e8));
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
        if (!Pairing.pairingProd4(
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
        uint[15] memory input
    ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for (uint i = 0; i < input.length; i++) {
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
