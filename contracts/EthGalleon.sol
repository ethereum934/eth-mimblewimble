pragma solidity >=0.4.21 < 0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract EthGalleon is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor () ERC20Detailed("EthGalleon", "GLN", 18) public {
        mint(address(this), 1000000 ether);
    }
}
