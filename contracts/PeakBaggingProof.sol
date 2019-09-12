pragma solidity >=0.4.21 < 0.6.0;

import "./LibSNARKs.sol";

contract PeakBaggingProof {
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
        vk.a = Pairing.G1Point(uint256(0x09b94b7dba55508bb789783e5a38e09cdd230a144f139efe88d496bc4d865fde), uint256(0x0b7876959615330fd12cc26ec8b3c7276488a2a8eb08ae14ed20d29088e61067));
        vk.b = Pairing.G2Point([uint256(0x0ec61e049fe09c99337f7891504305d76aed61209d5821ed9e1c8cebd7179b92), uint256(0x2b06db48de7f4ab4493e732664f835e87d0de77635bcb099306b3823d7ece258)], [uint256(0x1b35a993bfce4e915f501a7db0ecfd33da521c76bc9fc4e9d0ec73cab4a18386), uint256(0x30049e482b79d1707a158729219dcd423320122459c57e47d37b87b17aef276c)]);
        vk.gamma = Pairing.G2Point([uint256(0x1901206a0a3d0fb78346816d29afaa994921d5bb2b1c7852f8d4d06fe00a4c53), uint256(0x07cf664c39307d6aff66d793103690f0457e16d88e8fd2ef38dd79aa64de80ce)], [uint256(0x169113bdaf048b53cd576d66620ebeb60471253cecf6d77a5fa8ee3a899c28e9), uint256(0x2f09210b121ea66b18d65a1b62791bb0f32ac5ed30dc57979d0e2a8893cd1487)]);
        vk.delta = Pairing.G2Point([uint256(0x0738d70c9ac68284c74765af6c57afd5042c4c006cfc99e0d2dee64b0f23f8e0), uint256(0x03fbe0ced2541ea146fdeed305cbccc01ddd797d327ca20c8a836ca2f0071c6d)], [uint256(0x2066573d500aa9b8a5261e6598bf8bbe8bdb5ddc8f21a1ee9228f7b1d7d44a82), uint256(0x06777b377d8f989a87f3950b9205be3a596efcc2550ae3749405913102e86c78)]);
        vk.gamma_abc = new Pairing.G1Point[](36);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0e1cd176e7e641453fbd7c5db5395083e4465a67910394512dcf85aea6aa234b), uint256(0x17171a62a09d15cd8bdb7179d4ee698ac6cb558d7de404c3baf1b28e5466ff3d));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x021499a9c3c6516d768c08003ddf07424b624cd40ab3d79cc3cf347280491add), uint256(0x2477f6f5d7b219427478ae987af44f648709b6ef0b2967b7127a8d836edac004));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0af420e24de0750403d47f5487642b20b94cead9112683a44315b6ac799e521a), uint256(0x3044ad3527c3a021fdb4864a50f7b441d850c24ae8bfc38ad8904c6b72a2b549));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x25c370f77a8ea64b94b3df4d1f63904cd81577282fc1fc9e70aa795da1c40909), uint256(0x08692b322c8439baa91d62df51b72d17e5ea5a0521efbf6284733e96daa41185));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x08b3bca325603bbe4934dc004817826ce515cfc68e073d6644c902c3117da731), uint256(0x228e8fe172ecc5f82ae1f2b33087d325b1b6e4a851af68c8f7df0253f84c2ff6));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x126c2aa3c873fba1ea1e1cf4737eb93198bb7537f37727ec745254a88717d78a), uint256(0x257e58b37ccd2776e7bb1589371a9ec1837c723b40fdb831780364213c3e876b));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0fce3b6318e7db34eacfbde5531bf9a45062e0ee2989390179565318f63ccd8d), uint256(0x1bdf115546288d918c15ae4bd7f2730960bebb442345f3b7a79ee981b1026bb1));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x24bc928c3ffa6dd032a13ca3383d54e3037c8c96fc104cc038b95ebe9cf3bb94), uint256(0x0ecbb373580e5abb75bb78ceff70e38d622f77ae213f5b3679e9132818b11526));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0f6bbce2a0a01acec34d88fd726cd14de78e19d24a14724fadbd4a400e561bfb), uint256(0x22b4f70964313e77853db233b656a0b8c39c4a6c85f8338a97ce5418b2e98174));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2ebff28a994c74269239be9456795f6dcd00b828d2d44545d7c7647f5aadc94d), uint256(0x2b8f9a714c9b4d6c292d73148f7556b801f8f93b05062d416a1351139ce2fbc8));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0a9d549256e512aeb6c4b94cea68a0c6933d0aa48bc84590fb5cbe26e5ce0941), uint256(0x18d1af67131f5dae7521a0cede1773bb8d48bf48bb321dd72fbb3e5cfba7b7b7));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0c1b6c2103c13ac307472c5d374707f7260b723fc11e8c1ec8dcccd85ccd0221), uint256(0x1814dc8010a9ba5eb98666197d67ea0cdc0f882cd087b5fcb112c8b11534c8f7));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x140591f3a56af8657a4092e8475fd84034ff98d99c004da39a9acda01dde0f6c), uint256(0x16adc5826ccb917eeb98de70e22322ce8847d281b5d0140b4b403d54171775e7));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x114a6339dcb4ced8b2da157dbcbb1745d1de44ceff7c4086b0320623113bc455), uint256(0x246f35b7166310266154c1dc3a80b5ecf858eace793cf82e7d4a7d40341e83a1));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x24c7fdf96f7fa5fab74dab5681dec560d5c8449089568e829f316ba41714858e), uint256(0x1f73c2f6e2402b48d50ff03fc66cb8edff77f147fbe9ed286b2aadfc3bf5d02c));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x068ab7494b34dd2480fea33902a7a2492d781c45e87d6bf29af5dcb47cdb3ec7), uint256(0x207eaa3e8599bd36f183560b95ca09819a70d1c78d574f6aa7b6b19b4a6db8af));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x2e7ad618482e4797c3a411e4ee317f60fa116c7cb404876e423bd86369de65fd), uint256(0x1c3b940158a7377cb2b307c2983acc061d3e23458a50264b6acc1b820ef25215));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x0d897ca7b56e90de8aced8cbdcd1efca1e278e96a1fe66e15ecdce200fa560de), uint256(0x228f120c51b03c0e8c9e6f2bc1d3e23e1ff07b52d04de9f5e622b4ce5f1db804));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x06d1c6e0bf8d5ced49351122c5484e5543f5be35a4ba722644ae13d364d6d2dd), uint256(0x1354e47507cb203a42448db37367a9ec67b37bfe502e2555cab1d22e82272f9e));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x144a2ee834333215bd8724d5f23f3d83b9cdea1b2145688c888c7692b4db1c80), uint256(0x0e9cea455c95bfacdb8ff6c0859f92f405c3ff12ae1884ab72b8028e717422f2));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x268221455fa0b60aabf8bf76983da4015b1296c6ac1412624ea2ecf392d72205), uint256(0x02a7d52eb83cc6f7abf088e93c31b58d44c64925e41bdcf8dd437c220a69de32));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x2ef5234fd5027928dbe69fe394fca750f0f6e0643d4c8fafd1ac236290c7bf38), uint256(0x277d54dd6b87a46b53e282d5044b466f13b631e51ef1f3e41381594d11366c5d));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x196cbbf6d6f36e380641cca1fbef8db8514a137bfbcc827d3713da09fb22cd4c), uint256(0x091912831b0157657fa36794460b10309b845e1105d0acfdb3c1bb223bdb7065));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x14b5b5ec78e59e602c342d819ca3f8a2817c0f795370d1eb1dae4ec05a524afa), uint256(0x0bc7e70660b1060797b600788bd91e099c9ac663852ec3c4e870b808d21ce989));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x1e3a289a8222a994edc321e8c9e343dc3857c397619782b45929d0c0487a6649), uint256(0x1e71c51982fa98ca4e409804cce5af10da6e9cfc2180f6c6c3bec771bd61f6a0));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x189051a236265916bad93f086ed1fc3da63641a38c2c21c5ff8dd7ff652f3f00), uint256(0x0ecfd366b6a980c6ad0049cfb432f0482ec93f8f7eb42dba8180f4257e345007));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x210364e8b6ee34e77f8315b6e9d619c1923f9375fd955148817ae4c6e2e6b7f7), uint256(0x1fd5aa593bda60bf831f0a0ebfb1b7d8848f5f1d801f0d3ba52cf1698d49ad79));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x20b6e89da934c3dcf54e81049b45f7d09f70e8ea79d53ecfd5a0d195e55f2219), uint256(0x0034b213cf0fc2b7850b642cf4f36de0457570b6ee4151c6e23b860317f62de0));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x2990e6cb555c3599446d32c684e0ec2d6fea2a6d729c290b0518d284d7931c01), uint256(0x002e7f057d1e4118deca43dc5f4dd4d18f8cd6244ae7ded420d5b9615fe46bce));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x0f5faca9103248b60c10540bbe3405c254d0df9730de9fde4057de0ae33cfdb7), uint256(0x094aabe5e8deb7f8eeecc1cb9738d1583b05e65c860cf2ae64b4380a1d99699b));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x0d9df424018ccf8cccf63aa841b2ed857b9a29f790d53c7ae3d7ed7e7abfebc7), uint256(0x13122bab7443d187a4a71ba3622ef45526079f63020ad6589ef14f6e652cd28d));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x20ff600d361b026f7ba9446918a2bb73aa5f7ed5b2b6dd853f5612ab49c5b61d), uint256(0x1add4509630376df147ab90e68ab2159c0283bff843805d4f94692ceba19ee5f));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x2d780e757b4caaa71340cbb35fb3ccde39b88a29d3aeab5090c36ab94682d90c), uint256(0x0db87484fa293b93c751393c43aa034d01310aaefd187611cca628abff60c9d9));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x2f99eebc9bc1520c686aaf5767e70137d56cec85098887c597f45275bf179375), uint256(0x265a19c1bfd37189a599303a391685038d9f8a6bb4866220373ad8150ece2ce3));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x217424a2b7fde87755e29ccf850ed0dfa4492c7e2a6aae1d567ae17e18f93722), uint256(0x1c259a5e3c0ec98ff760c518a76649aa04fcdbbd4ee0e2bd7d68f8a4d0e532d5));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x08c3cb9692efa3442ee2239d8d98bfa16e9a1326d1de6c4c5b46e8415655352c), uint256(0x02dd8b27572a1ebf7271c2de5210596ca969ac9ec3880f2ddc0d50370cf1e6be));
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
        uint[35] memory input
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
