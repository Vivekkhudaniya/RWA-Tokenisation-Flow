import dotenv from 'dotenv';
dotenv.config();

function env(name: string, fallback: string): string {
  return process.env[name] ?? fallback;
}

export const config = {
  port: parseInt(env('PORT', '3000'), 10),
  rpcUrl: env('RPC_URL', 'http://127.0.0.1:8545'),
  tokenAddress: env('TOKEN_ADDRESS', '0x0000000000000000000000000000000000000000'),
  treasuryAddress: env('TREASURY_ADDRESS', '0x0000000000000000000000000000000000000000'),
  fromBlock: parseInt(env('FROM_BLOCK', '0'), 10),
};
