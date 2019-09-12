pragma solidity >=0.4.21 < 0.6.0;

import "./LibSNARKs.sol";

contract InclusionProof {
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
        vk.a = Pairing.G1Point(uint256(0x26544011c6c78a48d906705724fcf015145464dd2c6b9be0fd2b33119d064fd9), uint256(0x14a8653c55feabff57e834b825dac92a5fc677e1a7afa98164fe50dd879fd90c));
        vk.b = Pairing.G2Point([uint256(0x087cbed3f5f522fb38dae1f07926d4de8d08e3130ad4de41a071b1f78ba31ca4), uint256(0x0b55b84c5fab468734688efcb0a4d7f05002407470c0dab4c031ee0816f54d1c)], [uint256(0x14a25f3e17365235241197eb82fb070a1ff8aa7f43884986fe5601dc28bb8cc5), uint256(0x01dc92838e7bbfde60c8cf0e5410fa99eb075568363d0193c3130343f02aafa3)]);
        vk.gamma = Pairing.G2Point([uint256(0x1f8f44d34ea469503be3d024e635c584596e795fb0e73763b07712c630e7c02c), uint256(0x252702942f44b350584f2b6e601da2691b25ecfdec36c99ccaeae4dcad747296)], [uint256(0x214ca69d1bf081a1d70fed732f23b0e88aeef5e968525f2be8314e4f12282c09), uint256(0x1e35bc3a7ae78069edeff75605e73135b5be9b857ff94027b8f08406a74fa319)]);
        vk.delta = Pairing.G2Point([uint256(0x2d44a834e4841e831a126591263467ceb94ff4dd91196ab6efa19b59c207eefa), uint256(0x001f4bb1c528c654f355ec36310847f0adf6c4bcbbd7195d00f26a01dc68bb56)], [uint256(0x0dcdbeda5c918eaac19e259544804747643b93bdf33fab1310c22d68e1e940c1), uint256(0x10431609339e27ce05f6085667e105f106691524caaf1bfd6f4810e0ba726501)]);
        vk.gamma_abc = new Pairing.G1Point[](35);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x02da5b2e611c5475e23bcbcb1180ec12d355bdba10f60c48e59882b91b8ec5a5), uint256(0x2d6a6c6c9d624dc2a34ae6491e1385ad4b9646b5e9876732760fc2cf9153e0f6));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2111e9c278933bce877e53f5e0a3fe61e0a522246e06b57e7279399127ee550d), uint256(0x1492bd081f87dc219ebac213f5d2173b59d2ed2469fc055903202c2e37abd502));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x24cdcda9ab6071f30ae21da8c0f94312a8a13235d403b4e01cd7cc2746df4b4d), uint256(0x2f95d65e2f98f8d37028ee23e7fbfbca510d61b8c7cf52c51de9e9a894083d8a));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x25ffa2e1b93d1f29b5116da8a6c0b22cc12586c83cc666e674979ff90a753b01), uint256(0x276a1fa6f0d605045fd86dac0c82117b87bb20f9947b9bba349347414cb7fcff));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1b83ec794b50db8b7952e51ca86b2453b762c9722b1b613c35aba681ae899c98), uint256(0x03abb1cc9fbae890474429456c6353fa629b2451b8702a3ff042d7bee2ffc516));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x08af0b508fbf21a03e87b3046c7617d1e692a43da49480fa4cceb4af6b9833c3), uint256(0x0ac2d7bf6283dc47f23849f9958912d5490585ba2997fdca7bcd1b4fbbfb0255));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x271e51c4b2fc48fdeb3823b4c3da5bc26bee333f7d967810bf980ab2d7bb90a0), uint256(0x296787cbe53317f428dc271caf749a4ed38811886ceb02f11df24aebfcfe097b));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2c0bfd0ee33a025a0b5cb7cd9929ceba161e2f1c4223312e1bc505288ac3ff04), uint256(0x0adab6ca52be083ff5e3e744703754c9747a68ce4145c0059b0ecb4d412fbcaa));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0c842a00949b77cc8b0afa2c92e4a09fa445b20e8267a2ac3781535578c87ab9), uint256(0x20a0494389efc901728a664643c7d19f3acdc29df0d5dc1757bd7ffad7e83810));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2e8d2195f60b8ea3f8ed565de8112903937f6f6ae6ac66c5e20f30ff4086ea1e), uint256(0x25b12f7b1ae8e3f57bc4ea5fbc52d284370ca1456f4119f904b9d0161fa96d39));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2a7b65dd5134bc7520fa4c717ab2f70d2d521624053ec9281540d1eb09d7d580), uint256(0x268f9df0ef22c9f004406066809ce4d9840b0d5511de19323ab01392389ca8b7));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2efb35395618a817768f7a050c8916f537c26b74ec72302534655456b70d3920), uint256(0x16ebb578e957e703061fc73ae77038ff420da792193e1d91a03527caf535f2f4));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x052292f4f34e4440177fc5508bce7836fd48300c214a45bfa799206e96f17ccd), uint256(0x1b948b549e8133df86c6624b2e9292a6eb8da0150e845fcf980df7017c1c9749));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2112db177ac888bcdced303fcbcf02d5cf2a7bdcb8760df4611e9da1a26e09e1), uint256(0x10a15eac3ef2e746c22a258c05622a8271877c68cac71286eeddd384f7445a04));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1d9bbbe50188c52893832e07aecbfcf670438600bebb82415d8fbfdbed3891a4), uint256(0x1b41afc544360a61ec7bfd27447a25ec7d88c257d6ddf970de7ea7040b37e8fa));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x113516d25bb321b483205b46fa4746f883b063c9cce8e2e667cbbf3f7963a60a), uint256(0x2c9f4b07b80481f1d8fa7df9d2dffe0f5fcc803e7770ac173ba072b6c3e20902));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x03a95bd9490358a7e7641eac23aa5120b7afff541f79101ab44f7747cbc1613c), uint256(0x0cc6971ac80d0bc18d8e7413e30444b63f517cab321dace8deb7b1138536c5d1));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x1d05d1a110ad6c7e210d37ba18705f32b71b17ef63c584fe69b68f4ec64b0c7b), uint256(0x28cbb081295f19017f0278318a91c08e4a46e817cce65da24d5cbbb33dff1da9));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x03b1fbc843df714589adf70c86f65a2946f8603b2a7e39adc2f98b3690522416), uint256(0x00193902e3e5d72f49b798dccdb521201c3def1c94ce19108cf1b2b16383b7c4));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x0bd46affbdf4901e8973dada925be9101937a9346aa079cfdbc60217e36c1fda), uint256(0x0fbec2e18e2a22c6d987d3573c52c3d5f46a5508fc73e3a3c8d5e291ed8e665c));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x113e233b9e31c96eead13dca92310ebfcb6808ec84eb9d214891f3c9ad7ba5a8), uint256(0x2440ab5c8c1892af52069d381c022cb40044d775ecccf32949fbd8eb702a9a4d));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x198e813519f2486ae26dd72bf0ab3cb4f2b2f08d6b01557c5fe25d974f276c81), uint256(0x02b5f4bd1d6894bbaff9572fc7c6382036e46f368f3e22feefede8b0fe62ec68));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x0342c3217503ae134126fbf9a1528f95bdd8da6d19fa91318f90627323b493f9), uint256(0x095e74b583e92786357d6b7bd3760a8ca6ad1551cf20ef6efd544ebf152b642d));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x2ea3c502d1d236259f8e3646049f68d78b5a3771c9719e6eda669cc8a411e7d6), uint256(0x2c2a02a50f2718158e33e36383af68193a9c1812bd3006095bd4d541930c2d86));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x21e515745727997be0de25147af3854e00fca0719f52f75aa94a229b43fcc77e), uint256(0x11ab6dfaeffa3c662286c4397fe485cc83098e73123971c16a666068c9d8fb66));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1f72639ef739c7990c7c0331a3f1b0e505514fcc827328577bb938f924d8bd3d), uint256(0x03938eab7e3e74ec5790df7ab46aa364f6c176d2fa06b8c875db921bd42c27fb));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x11af75c0f160ec5dde4a8fa83f10c11d08664b72381fc45794f5c2fe5d91220e), uint256(0x2b05ec19464306e7016a0f36fb2d60dfb24b11bd59441e68da8279cbe6e1c79a));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x15351738d608e1e8de13149ddbddb6670fbc28e5d66367f1a31db937ab95e608), uint256(0x26f25367e9624138c81ca7245bb819651ac8f1c8835714e4fdf0bf11b25b4b5a));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x26d355da035c3c9d27affc4118dcc40e305b34ac65262ee038dce77b87dea082), uint256(0x2d64c9461c470a5dd0267b2fc105a8c6cd7876a8ae77aa4e70e33499a88a855c));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x0d80d56c7366dc343e0494faa04886cf3ebf2170c4450f62eb65aeff7a74143c), uint256(0x06b940d23f8bfbb132e2453e7910449ec2af7467417c7b9bc4d0b1acb1abe8ae));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x1a9d7227ec3992727b87ca824634b77f3547776235af44f96dee5acaf2bf8884), uint256(0x0dd66f32a0456c0284f8161c84040d15c572e5c9f947ef156441b19ea459334d));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x085a58f037213f0a0073611ad22e05c19cb9cac36ccb409ac1f793e70df0df29), uint256(0x157bff8fa945da98761ea63fc2676039744d32abfff28045ee5253bf1d635418));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x01334076fecc9577452c692fbe3d0f81644b5ddf32c0ab7de6caae702b9f26d0), uint256(0x267155708d5f98dc8cdfb99d7d3dd91bfa6922b0080c52c0e5ec26c71e3e35fe));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x09278d73f98a3bcdfdbc57bb76162690935b9eaac8fc4ee96a3efdd67beb5cc3), uint256(0x1cd2355b5acbc46c6004b9ce524600f261650c7e4456c1ed670340dc7aec2b18));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x16e7a1bb98d259497689def95e6c65306b4986e3a36d74110469a1b113164779), uint256(0x0d9d561d23c36b27925b9ab74e2eb839a6757ae750cb60b0e939d8d67cabf510));
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
        uint[34] memory input
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
