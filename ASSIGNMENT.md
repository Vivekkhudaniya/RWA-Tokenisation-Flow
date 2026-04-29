## Assignment: Minimal RWA Tokenisation Flow

You have 2 working days to complete the assignment.
Please submit your results to hr@weare86.com

---

### Objective

Build a simplified system that simulates a real-world asset (RWA) tokenisation flow, including smart contracts, backend integration, and basic testing.

---

### Scope of Work

#### 1. Smart Contracts (Solidity)

Develop the following:

**a. ERC20 Token Contract**
- Represents fractional ownership of an asset
- Should allow minting based on treasury interaction

**b. Treasury Contract**
- Accept deposits (mock ETH or token)
- Mint tokens to users upon deposit
- Allow withdrawals (restricted to admin/owner)
- Implement basic access control (Ownable or role-based)

#### 2. Backend (Node.js / TypeScript)

Build a simple backend service with the following APIs:

- **Get Wallet Balance** — Input: Wallet address | Output: Token balance
- **Get Transaction History** — Can be event-based or mocked; should return recent transactions
- **Deposit Preview API** — Input: Amount | Output: Expected tokens to be minted

#### 3. Testing

Include at least 2–3 test cases covering:
- Deposit flow
- Withdrawal flow
- One edge case (invalid input / unauthorized access)

You may use Foundry or Hardhat for testing.

#### 4. Deliverables

Please submit the following:

GitHub repository containing:
- Smart contracts
- Backend code
- Tests
- A README.md file including:
  - Setup and installation steps
  - How to run the project
  - Brief explanation of your design decisions

*(Optional but preferred)* Deployed contract address on any EVM-compatible testnet

---

### Evaluation Criteria

Your submission will be evaluated based on:
- Code structure and clarity
- Backend implementation quality
- Test coverage and correctness
- Documentation and explanation
- Overall approach and effort

---

### Timeline

Please complete and submit the assignment within 48 hours from the time of receiving this email.

### Submission Instructions

Share your GitHub repository link by replying to this email.
