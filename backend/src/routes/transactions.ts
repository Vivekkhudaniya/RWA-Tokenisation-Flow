import { Router, Request, Response } from 'express';
import { ethers } from 'ethers';
import { getContracts } from '../contracts';
import { config } from '../config';

const router = Router();

// GET /transactions/:address
// Returns all Deposited and Withdrawn events involving a given address, newest first.
router.get('/:address', async (req: Request, res: Response) => {
  const { address } = req.params;

  if (!ethers.isAddress(address)) {
    return res.status(400).json({ error: 'Invalid Ethereum address' });
  }

  try {
    const { treasury } = getContracts();

    const [depositEvents, withdrawEvents] = await Promise.all([
      treasury.queryFilter(treasury.filters.Deposited(address), config.fromBlock),
      treasury.queryFilter(treasury.filters.Withdrawn(address), config.fromBlock),
    ]);

    const deposits = (depositEvents as ethers.EventLog[]).map((log) => ({
      type: 'deposit',
      txHash: log.transactionHash,
      blockNumber: log.blockNumber,
      depositor: log.args[0] as string,
      ethAmount: (log.args[1] as bigint).toString(),
      tokensMinted: (log.args[2] as bigint).toString(),
    }));

    const withdrawals = (withdrawEvents as ethers.EventLog[]).map((log) => ({
      type: 'withdrawal',
      txHash: log.transactionHash,
      blockNumber: log.blockNumber,
      recipient: log.args[0] as string,
      ethAmount: (log.args[1] as bigint).toString(),
    }));

    const all = [...deposits, ...withdrawals].sort((a, b) => b.blockNumber - a.blockNumber);

    return res.json({ address, transactions: all });
  } catch {
    return res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

export default router;
