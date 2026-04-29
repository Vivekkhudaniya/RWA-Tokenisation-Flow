# RWA Tokenisation Flow

A minimal Real-World Asset (RWA) tokenisation system built with Solidity + Foundry and a Node.js/TypeScript backend.

---

## Architecture Overview

```
RWAToken (ERC20)
  └── owned by Treasury (mint/burn authority)

Treasury
  ├── deposit()       — user sends ETH → receives RWA tokens
  ├── previewDeposit()— read-only preview of token amount for a given ETH
  ├── withdraw()      — owner withdraws a specific ETH amount
  └── withdrawAll()   — owner drains the entire treasury
```

**Exchange rate:** 1000 RWA tokens per 1 ETH (fixed at deployment).

---

## Project Structure

```
RWA-Tokenisation-Flow/
├── contracts/               # Foundry project
│   ├── src/
│   │   ├── RWAToken.sol     # ERC20 fractional-ownership token
│   │   └── Treasury.sol     # Deposit/mint/withdraw logic
│   ├── test/
│   │   └── Treasury.t.sol   # 21 unit + fuzz tests
│   ├── script/
│   │   └── Deploy.s.sol     # Deployment script
│   └── foundry.toml
└── backend/                 # Node.js / TypeScript API (coming soon)
```

---

## Setup & Installation

### Prerequisites

| Tool | Version |
|------|---------|
| [Foundry](https://book.getfoundry.sh/getting-started/installation) | ≥ 1.0 |
| Node.js | ≥ 18 |

### 1. Clone the repo

```bash
git clone <repo-url>
cd RWA-Tokenisation-Flow
```

### 2. Install contract dependencies

```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts --no-git
```

---

## Running Tests

```bash
cd contracts
forge test -vv
```

Expected output:

```
Ran 21 tests for test/Treasury.t.sol:TreasuryTest
Suite result: ok. 21 passed; 0 failed; 0 skipped
```

Run with gas snapshots:

```bash
forge test --gas-report
```

---

## Deploying

```bash
cd contracts
cp .env.example .env        # fill in PRIVATE_KEY and RPC_URL
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

---

## Smart Contracts

### `RWAToken.sol`

- Standard ERC-20 (OpenZeppelin v5) with configurable decimals.
- `mint` and `burn` are `onlyOwner` — ownership is transferred to the Treasury at deploy time so only the Treasury can create or destroy tokens.

### `Treasury.sol`

- **Deposit:** `deposit()` is `payable`; ETH sent → tokens minted proportionally. A plain ETH transfer via `receive()` is also handled identically.
- **Preview:** `previewDeposit(ethAmount)` is a pure read-only helper used by the backend API to quote token amounts before a transaction.
- **Withdrawal:** `withdraw(amount)` and `withdrawAll()` are `onlyOwner`. Both are protected by `ReentrancyGuard`.
- **Access control:** OpenZeppelin `Ownable` (v5). Non-owner calls to withdraw revert with `OwnableUnauthorizedAccount`.
- **Custom errors:** `ZeroDeposit`, `ZeroTokensPerEth`, `WithdrawFailed`, `InsufficientTreasuryBalance` — gas-efficient reverts with structured data.

---

## Test Coverage

| Test | Category |
|------|----------|
| `test_InitialState` | Sanity |
| `test_PreviewDeposit_*` (×3) | Preview |
| `testFuzz_PreviewDeposit` (256 runs) | Fuzz |
| `test_Deposit_MintsCorrectTokens` | Deposit flow |
| `test_Deposit_MultipleUsers` | Deposit flow |
| `test_Deposit_ViaReceiveFallback` | Deposit flow |
| `testFuzz_Deposit` (256 runs) | Fuzz |
| `test_Withdraw_PartialAmount` | Withdrawal flow |
| `test_Withdraw_FullBalance` | Withdrawal flow |
| `test_WithdrawAll_AfterMultipleDeposits` | Withdrawal flow |
| `test_Revert_ZeroDeposit` | Edge case |
| `test_Revert_NonOwnerCannotWithdraw` | Access control |
| `test_Revert_NonOwnerCannotWithdrawAll` | Access control |
| `test_Revert_WithdrawExceedsBalance` | Edge case |
| `test_Revert_WithdrawAllWhenEmpty` | Edge case |
| `test_Revert_DirectMintNotAllowedByNonOwner` | Access control |
| `test_Revert_ZeroTokensPerEth` | Edge case |
| `test_TokenOwnerIsAlwaysTreasury` | Invariant |
| `test_TotalSupplyMatchesAllMints` | Invariant |

---

## Design Decisions

1. **Ownership model:** `RWAToken` ownership is transferred to `Treasury` post-deployment. This keeps minting authority entirely inside the treasury and prevents any EOA from minting tokens directly.

2. **Fixed exchange rate:** `TOKENS_PER_ETH` is set at construction and stored as an immutable. This is intentional for simplicity; a production system would use an oracle or a bonding curve.

3. **ReentrancyGuard on all ETH-moving functions:** `deposit`, `withdraw`, and `withdrawAll` all hold the reentrancy lock. This prevents any callback-based drain even if the owner address is a contract.

4. **Custom errors over `require` strings:** All reverts use typed custom errors (`ZeroDeposit`, `InsufficientTreasuryBalance`, etc.) for lower gas cost and easier off-chain parsing.

5. **`previewDeposit` as a pure view:** The backend calls this read-only function to quote token amounts without sending a transaction, matching the "Deposit Preview API" requirement exactly.

6. **`receive()` parity:** Direct ETH transfers are treated identically to `deposit()` calls so that wallets that don't call the ABI-encoded method still work correctly.
