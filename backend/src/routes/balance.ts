import { Router, Request, Response } from 'express';
import { ethers } from 'ethers';
import { getContracts } from '../contracts';

const router = Router();

// GET /balance/:address
// Returns the RWA token balance of a wallet address.
router.get('/:address', async (req: Request, res: Response) => {
  const { address } = req.params;

  if (!ethers.isAddress(address)) {
    return res.status(400).json({ error: 'Invalid Ethereum address' });
  }

  try {
    const { token } = getContracts();
    const [balance, decimals, symbol] = await Promise.all([
      token.balanceOf(address),
      token.decimals(),
      token.symbol(),
    ]);

    return res.json({
      address,
      balance: balance.toString(),
      formatted: ethers.formatUnits(balance, decimals),
      symbol,
    });
  } catch {
    return res.status(500).json({ error: 'Failed to fetch balance' });
  }
});

export default router;
