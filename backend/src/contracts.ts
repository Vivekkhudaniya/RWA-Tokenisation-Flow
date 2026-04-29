import { ethers } from 'ethers';
import { config } from './config';
import RWATokenABI from './abis/RWAToken.json';
import TreasuryABI from './abis/Treasury.json';

// Lazily initialised — safe to call multiple times
let provider: ethers.JsonRpcProvider | null = null;
let token: ethers.Contract | null = null;
let treasury: ethers.Contract | null = null;

export function getContracts() {
  if (!provider) {
    provider = new ethers.JsonRpcProvider(config.rpcUrl);
  }
  if (!token) {
    token = new ethers.Contract(config.tokenAddress, RWATokenABI, provider);
  }
  if (!treasury) {
    treasury = new ethers.Contract(config.treasuryAddress, TreasuryABI, provider);
  }
  return { token, treasury, provider };
}
