pragma solidity >=0.4.21 < 0.6.0;

/**
 * This solidity is to get artifacts of automatically generated contracts for a testing purpose.
 */

import {Verifier as ZkDeposit} from "./generated/DepositVerifier.sol";
import {Verifier as ZkMimblewimble} from "./generated/MimblewimbleVerifier.sol";
import {Verifier as ZkMMRInclusion} from "./generated/MMRInclusionVerifier.sol";
import {Verifier as ZkRangeProof} from "./generated/RangeProofVerifier.sol";
import {Verifier as ZkRollUp1} from "./generated/RollUp1Verifier.sol";
import {Verifier as ZkRollUp2} from "./generated/RollUp2Verifier.sol";
import {Verifier as ZkRollUp4} from "./generated/RollUp4Verifier.sol";
import {Verifier as ZkRollUp8} from "./generated/RollUp8Verifier.sol";
import {Verifier as ZkRollUp16} from "./generated/RollUp16Verifier.sol";
import {Verifier as ZkRollUp32} from "./generated/RollUp32Verifier.sol";
import {Verifier as ZkRollUp64} from "./generated/RollUp64Verifier.sol";
import {Verifier as ZkRollUp128} from "./generated/RollUp128Verifier.sol";
import {Verifier as ZkWithdraw} from "./generated/WithdrawVerifier.sol";

contract DepositVerifier is ZkDeposit {
}

contract MimblewimbleVerifier is ZkMimblewimble {
}

contract MMRInclusionVerifier is ZkMMRInclusion {
}

contract RangeProofVerifier is ZkRangeProof {
}

contract RollUp1Verifier is ZkRollUp1 {
}

contract RollUp2Verifier is ZkRollUp2 {
}

contract RollUp4Verifier is ZkRollUp4 {
}

contract RollUp8Verifier is ZkRollUp8 {
}

contract RollUp16Verifier is ZkRollUp16 {
}

contract RollUp32Verifier is ZkRollUp32 {
}

contract RollUp64Verifier is ZkRollUp64 {
}

contract RollUp128Verifier is ZkRollUp128 {
}

contract WithdrawVerifier is ZkWithdraw {
}
