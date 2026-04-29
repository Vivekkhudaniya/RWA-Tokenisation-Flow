// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {RWAToken} from "./RWAToken.sol";

/// @notice Treasury accepts ETH deposits and mints RWAToken proportionally.
///         The exchange rate is fixed at deployment: TOKENS_PER_ETH RWA tokens per 1 ETH.
///         Only the owner can withdraw ETH from the treasury.
contract Treasury is Ownable, ReentrancyGuard {
    RWAToken public immutable TOKEN;

    /// @notice How many RWA tokens are minted per 1 ETH deposited (18-decimal precision).
    uint256 public immutable TOKENS_PER_ETH;

    uint256 public totalDeposited;

    event Deposited(address indexed depositor, uint256 ethAmount, uint256 tokensMinted);
    event Withdrawn(address indexed recipient, uint256 ethAmount);

    error ZeroDeposit();
    error ZeroTokensPerEth();
    error WithdrawFailed();
    error InsufficientTreasuryBalance(uint256 requested, uint256 available);

    constructor(
        address tokenAddress,
        uint256 tokensPerEth,
        address initialOwner
    ) Ownable(initialOwner) {
        if (tokensPerEth == 0) revert ZeroTokensPerEth();
        TOKEN = RWAToken(tokenAddress);
        TOKENS_PER_ETH = tokensPerEth;
    }

    /// @notice Deposit ETH and receive RWA tokens proportional to the exchange rate.
    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert ZeroDeposit();

        uint256 tokensToMint = previewDeposit(msg.value);
        totalDeposited += msg.value;

        TOKEN.mint(msg.sender, tokensToMint);
        emit Deposited(msg.sender, msg.value, tokensToMint);
    }

    /// @notice Returns the token amount a given ETH deposit would produce.
    function previewDeposit(uint256 ethAmount) public view returns (uint256) {
        return (ethAmount * TOKENS_PER_ETH) / 1 ether;
    }

    /// @notice Owner withdraws a specific ETH amount from the treasury.
    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (amount > balance) revert InsufficientTreasuryBalance(amount, balance);

        (bool success, ) = owner().call{value: amount}("");
        if (!success) revert WithdrawFailed();

        emit Withdrawn(owner(), amount);
    }

    /// @notice Owner withdraws all ETH from the treasury.
    function withdrawAll() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientTreasuryBalance(0, 0);

        (bool success, ) = owner().call{value: balance}("");
        if (!success) revert WithdrawFailed();

        emit Withdrawn(owner(), balance);
    }

    receive() external payable {
        if (msg.value > 0) {
            uint256 tokensToMint = previewDeposit(msg.value);
            totalDeposited += msg.value;
            TOKEN.mint(msg.sender, tokensToMint);
            emit Deposited(msg.sender, msg.value, tokensToMint);
        }
    }
}
