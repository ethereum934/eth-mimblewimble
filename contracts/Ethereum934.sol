pragma solidity >=0.4.21 < 0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ZkInterfaces.sol";

contract Ethereum934 {

    struct MMR {
        mapping(uint => bool) roots;
        uint root;
        uint16 width;
    }

    ZkDeposit zkDeposit;
    ZkMimblewimble zkMimblewimble;
    ZkMMRInclusion zkMMRInclusion;
    ZkRollUp1 zkRollUp1;
    ZkRollUp2 zkRollUp2;
    ZkRollUp4 zkRollUp4;
    ZkRollUp8 zkRollUp8;
    ZkRollUp16 zkRollUp16;
    ZkWithdraw zkWithdraw;

    constructor(
        address zkDepositAddr,
        address zkMimblewimbleAddr,
        address zkMMRInclusionAddr,
        address zkRollUp1Addr,
        address zkRollUp2Addr,
        address zkRollUp4Addr,
        address zkRollUp8Addr,
        address zkRollUp16Addr,
        address zkWithdrawAddr
    ) public {
        zkDeposit = ZkDeposit(zkDepositAddr);
        zkMimblewimble = ZkMimblewimble(zkMimblewimbleAddr);
        zkMMRInclusion = ZkMMRInclusion(zkMMRInclusionAddr);
        zkRollUp1 = ZkRollUp1(zkRollUp1Addr);
        zkRollUp2 = ZkRollUp2(zkRollUp2Addr);
        zkRollUp4 = ZkRollUp4(zkRollUp4Addr);
        zkRollUp8 = ZkRollUp8(zkRollUp8Addr);
        zkRollUp16 = ZkRollUp16(zkRollUp16Addr);
        zkWithdraw = ZkWithdraw(zkWithdrawAddr);
    }

    mapping(address => MMR) public mmrs;
    mapping(address => uint) public deposits;
    mapping(address => mapping(uint => bool)) public spentTags;
    mapping(uint => bool) public depositTags;


    function depositToMagicalWorld(address erc20, uint amount, uint depositTag) public {
        IERC20 token = IERC20(erc20);
        token.transferFrom(msg.sender, address(this), amount);
        deposits[erc20] += amount;
        depositTags[depositTag] = true;
    }

    function withdrawToMuggleWorld(
        address erc20,
        uint tag,
        uint value,
        uint root,
        uint[2][16] memory peaks,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c
    ) public {
        // Check double spending
        require(!spentTags[erc20][tag], "Should not already have been spent");
        uint[36] memory inputs = [tag, value, root,
        peaks[0][0], peaks[1][0], peaks[2][0], peaks[3][0], peaks[4][0], peaks[5][0], peaks[6][0], peaks[7][0], peaks[8][0], peaks[9][0], peaks[10][0], peaks[11][0], peaks[12][0], peaks[13][0], peaks[14][0], peaks[15][0],
        peaks[0][1], peaks[1][1], peaks[2][1], peaks[3][1], peaks[4][1], peaks[5][1], peaks[6][1], peaks[7][1], peaks[8][1], peaks[9][1], peaks[10][1], peaks[11][1], peaks[12][1], peaks[13][1], peaks[14][1], peaks[15][1],
        1];
        // Check the tag is derived from a unknown TXO belonging to the MMR trees
        //        require(zkWithdrawProof(a, b, c, inputs), "Should satisfy the zkp condition");
        // Record as spent
        spentTags[erc20][tag] = true;
        // Transfer
        IERC20(erc20).transfer(msg.sender, value);
    }

    function _rollUp(uint root, uint width, uint[2][16] memory items, uint newRoot, uint[8][16] memory rangeProofs, uint[9][16] memory inclusionProofs, uint[8] memory rollUpProof) private {
        // Check peak bagging
        // Check range proofs of new TXOs
        // Check inclusion proofs or deposit proofs of new TXOs
        // Check roll up proof
        // Update the root and width or create new tree
    }
}
