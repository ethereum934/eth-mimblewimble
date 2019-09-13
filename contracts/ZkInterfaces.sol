pragma solidity >=0.4.21 < 0.6.0;

interface ZkDeposit {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[3] calldata input
    ) external returns (bool r);
}

interface ZkMimblewimble {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[11] calldata input
    ) external returns (bool r);
}

interface ZkMMRInclusion {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[3] calldata input
    ) external returns (bool r);
}

interface ZkRangeProof {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input
    ) external returns (bool r);
}
interface ZkRollUp1 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[6] calldata input
    ) external returns (bool r);
}
interface ZkRollUp2 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[8] calldata input
    ) external returns (bool r);
}
interface ZkRollUp4 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[12] calldata input
    ) external returns (bool r);
}
interface ZkRollUp8 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[20] calldata input
    ) external returns (bool r);
}
interface ZkRollUp16 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[36] calldata input
    ) external returns (bool r);
}
interface ZkRollUp32 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[68] calldata input
    ) external returns (bool r);
}
interface ZkRollUp64 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[132] calldata input
    ) external returns (bool r);
}
interface ZkRollUp128 {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[260] calldata input
    ) external returns (bool r);
}
interface ZkWithdraw {
    function verifyTx(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[4] calldata input
    ) external returns (bool r);
}
