// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {RWAToken} from "../src/RWAToken.sol";
import {Treasury} from "../src/Treasury.sol";

contract TreasuryTest is Test {
    RWAToken internal token;
    Treasury internal treasury;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    // 1000 RWA tokens (18 decimals) per 1 ETH
    uint256 internal constant TOKENS_PER_ETH = 1000 * 1e18;

    event Deposited(address indexed depositor, uint256 ethAmount, uint256 tokensMinted);
    event Withdrawn(address indexed recipient, uint256 ethAmount);

    function setUp() public {
        vm.startPrank(owner);

        token = new RWAToken("RWA Token", "RWA", 18, owner);
        treasury = new Treasury(address(token), TOKENS_PER_ETH, owner);

        // Transfer token ownership to treasury so it can mint
        token.transferOwnership(address(treasury));

        vm.stopPrank();

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Deployment sanity
    // ─────────────────────────────────────────────────────────────────────────

    function test_InitialState() public view {
        assertEq(address(treasury.TOKEN()), address(token));
        assertEq(treasury.TOKENS_PER_ETH(), TOKENS_PER_ETH);
        assertEq(treasury.owner(), owner);
        assertEq(token.owner(), address(treasury));
        assertEq(token.totalSupply(), 0);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // previewDeposit
    // ─────────────────────────────────────────────────────────────────────────

    function test_PreviewDeposit_OneEth() public view {
        assertEq(treasury.previewDeposit(1 ether), 1000 * 1e18);
    }

    function test_PreviewDeposit_HalfEth() public view {
        assertEq(treasury.previewDeposit(0.5 ether), 500 * 1e18);
    }

    function test_PreviewDeposit_FractionalEth() public view {
        // 0.001 ETH → 1 RWA token
        assertEq(treasury.previewDeposit(0.001 ether), 1e18);
    }

    function testFuzz_PreviewDeposit(uint96 ethAmount) public view {
        uint256 expected = (uint256(ethAmount) * TOKENS_PER_ETH) / 1 ether;
        assertEq(treasury.previewDeposit(ethAmount), expected);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Deposit flow
    // ─────────────────────────────────────────────────────────────────────────

    function test_Deposit_MintsCorrectTokens() public {
        uint256 depositAmount = 2 ether;
        uint256 expectedTokens = treasury.previewDeposit(depositAmount);

        vm.expectEmit(true, false, false, true);
        emit Deposited(alice, depositAmount, expectedTokens);

        vm.prank(alice);
        treasury.deposit{value: depositAmount}();

        assertEq(token.balanceOf(alice), expectedTokens);
        assertEq(address(treasury).balance, depositAmount);
        assertEq(treasury.totalDeposited(), depositAmount);
        assertEq(token.totalSupply(), expectedTokens);
    }

    function test_Deposit_MultipleUsers() public {
        vm.prank(alice);
        treasury.deposit{value: 1 ether}();

        vm.prank(bob);
        treasury.deposit{value: 2 ether}();

        assertEq(token.balanceOf(alice), 1000 * 1e18);
        assertEq(token.balanceOf(bob), 2000 * 1e18);
        assertEq(address(treasury).balance, 3 ether);
        assertEq(treasury.totalDeposited(), 3 ether);
    }

    function test_Deposit_ViaReceiveFallback() public {
        uint256 depositAmount = 1 ether;
        uint256 expectedTokens = treasury.previewDeposit(depositAmount);

        vm.prank(alice);
        (bool ok, ) = address(treasury).call{value: depositAmount}("");
        assertTrue(ok);

        assertEq(token.balanceOf(alice), expectedTokens);
    }

    function testFuzz_Deposit(uint96 rawAmount) public {
        uint256 amount = uint256(rawAmount);
        vm.assume(amount > 0 && amount <= 10 ether);

        uint256 expectedTokens = treasury.previewDeposit(amount);

        vm.deal(alice, amount);
        vm.prank(alice);
        treasury.deposit{value: amount}();

        assertEq(token.balanceOf(alice), expectedTokens);
        assertEq(address(treasury).balance, amount);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Withdrawal flow (owner only)
    // ─────────────────────────────────────────────────────────────────────────

    function _depositAs(address user, uint256 amount) internal {
        vm.prank(user);
        treasury.deposit{value: amount}();
    }

    function test_Withdraw_PartialAmount() public {
        _depositAs(alice, 3 ether);

        uint256 ownerBalanceBefore = owner.balance;

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(owner, 1 ether);

        vm.prank(owner);
        treasury.withdraw(1 ether);

        assertEq(address(treasury).balance, 2 ether);
        assertEq(owner.balance, ownerBalanceBefore + 1 ether);
    }

    function test_Withdraw_FullBalance() public {
        _depositAs(alice, 2 ether);

        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        treasury.withdrawAll();

        assertEq(address(treasury).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + 2 ether);
    }

    function test_WithdrawAll_AfterMultipleDeposits() public {
        _depositAs(alice, 1 ether);
        _depositAs(bob, 2 ether);

        uint256 ownerBefore = owner.balance;

        vm.prank(owner);
        treasury.withdrawAll();

        assertEq(address(treasury).balance, 0);
        assertEq(owner.balance, ownerBefore + 3 ether);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Edge cases / access control
    // ─────────────────────────────────────────────────────────────────────────

    function test_Revert_ZeroDeposit() public {
        vm.prank(alice);
        vm.expectRevert(Treasury.ZeroDeposit.selector);
        treasury.deposit{value: 0}();
    }

    function test_Revert_NonOwnerCannotWithdraw() public {
        _depositAs(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice)
        );
        treasury.withdraw(1 ether);
    }

    function test_Revert_NonOwnerCannotWithdrawAll() public {
        _depositAs(alice, 1 ether);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", bob)
        );
        treasury.withdrawAll();
    }

    function test_Revert_WithdrawExceedsBalance() public {
        _depositAs(alice, 1 ether);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                Treasury.InsufficientTreasuryBalance.selector,
                2 ether,
                1 ether
            )
        );
        treasury.withdraw(2 ether);
    }

    function test_Revert_WithdrawAllWhenEmpty() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                Treasury.InsufficientTreasuryBalance.selector,
                uint256(0),
                uint256(0)
            )
        );
        treasury.withdrawAll();
    }

    function test_Revert_DirectMintNotAllowedByNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice)
        );
        token.mint(alice, 1e18);
    }

    function test_Revert_ZeroTokensPerEth() public {
        vm.prank(owner);
        vm.expectRevert(Treasury.ZeroTokensPerEth.selector);
        new Treasury(address(token), 0, owner);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Invariants
    // ─────────────────────────────────────────────────────────────────────────

    function test_TokenOwnerIsAlwaysTreasury() public view {
        assertEq(token.owner(), address(treasury));
    }

    function test_TotalSupplyMatchesAllMints() public {
        _depositAs(alice, 1 ether);
        _depositAs(bob, 3 ether);

        uint256 expectedSupply = treasury.previewDeposit(1 ether) + treasury.previewDeposit(3 ether);
        assertEq(token.totalSupply(), expectedSupply);
    }
}
