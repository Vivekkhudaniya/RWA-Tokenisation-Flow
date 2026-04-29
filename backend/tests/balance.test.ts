import request from 'supertest';
import app from '../src/app';
import { getContracts } from '../src/contracts';

jest.mock('../src/contracts');

const mockGetContracts = getContracts as jest.MockedFunction<typeof getContracts>;

const VALID_ADDRESS = '0x742d35Cc6634C0532925a3b844Bc454e4438f44e';
const BALANCE_RAW = 2000n * 10n ** 18n; // 2000 RWA tokens

describe('GET /balance/:address', () => {
  beforeEach(() => {
    mockGetContracts.mockReturnValue({
      token: {
        balanceOf: jest.fn().mockResolvedValue(BALANCE_RAW),
        decimals: jest.fn().mockResolvedValue(18),
        symbol: jest.fn().mockResolvedValue('RWA'),
      } as any,
      treasury: {} as any,
      provider: {} as any,
    });
  });

  it('returns token balance for a valid address', async () => {
    const res = await request(app).get(`/balance/${VALID_ADDRESS}`);

    expect(res.status).toBe(200);
    expect(res.body.address).toBe(VALID_ADDRESS);
    expect(res.body.balance).toBe(BALANCE_RAW.toString());
    expect(res.body.symbol).toBe('RWA');
    expect(res.body.formatted).toBeDefined();
  });

  it('returns 400 for an invalid Ethereum address', async () => {
    const res = await request(app).get('/balance/not-an-address');

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Invalid Ethereum address');
  });

  it('returns 400 for a missing address segment', async () => {
    const res = await request(app).get('/balance/');

    // Express returns 404 for missing route params
    expect(res.status).toBe(404);
  });

  it('returns 500 when the contract call fails', async () => {
    mockGetContracts.mockReturnValue({
      token: {
        balanceOf: jest.fn().mockRejectedValue(new Error('RPC error')),
        decimals: jest.fn().mockRejectedValue(new Error('RPC error')),
        symbol: jest.fn().mockRejectedValue(new Error('RPC error')),
      } as any,
      treasury: {} as any,
      provider: {} as any,
    });

    const res = await request(app).get(`/balance/${VALID_ADDRESS}`);

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('Failed to fetch balance');
  });
});
