import { Router, Request, Response } from 'express';
import { ethers } from 'ethers';
import { getContracts } from '../contracts';

const router = Router();

// GET /preview?amount=<ETH>
// Returns how many RWA tokens would be minted for a given ETH amount.
router.get('/', async (req: Request, res: Response) => {
  const { amount } = req.query;

  if (!amount || typeof amount !== 'string') {
    return res.status(400).json({ error: 'amount query param is required (e.g. ?amount=1.5)' });
  }

  let ethAmount: bigint;
  try {
    ethAmount = ethers.parseEther(amount);
  } catch {
    return res.status(400).json({ error: 'Invalid amount — must be a valid ETH value (e.g. "1.5")' });
  }

  if (ethAmount <= 0n) {
    return res.status(400).json({ error: 'Amount must be greater than 0' });
  }

  try {
    const { treasury, token } = getContracts();
    const [tokensToMint, decimals, symbol] = await Promise.all([
      treasury.previewDeposit(ethAmount),
      token.decimals(),
      token.symbol(),
    ]);

    return res.json({
      ethAmount: amount,
      tokensToMint: tokensToMint.toString(),
      formatted: ethers.formatUnits(tokensToMint, decimals),
      symbol,
    });
  } catch {
    return res.status(500).json({ error: 'Failed to preview deposit' });
  }
});

export default router;
