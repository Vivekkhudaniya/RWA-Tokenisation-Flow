// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice ERC20 token representing fractional ownership of a real-world asset.
///         Only the Treasury contract (set as owner) can mint or burn tokens.
contract RWAToken is ERC20, Ownable {
    uint8 private immutable DECIMALS;

    constructor(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        DECIMALS = tokenDecimals;
    }

    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
