import request from 'supertest';
import app from '../src/app';
import { getContracts } from '../src/contracts';

jest.mock('../src/contracts');

const mockGetContracts = getContracts as jest.MockedFunction<typeof getContracts>;

// 1 ETH → 1000 RWA tokens (matches contract rate)
const TOKENS_FOR_1_ETH = 1000n * 10n ** 18n;

describe('GET /preview', () => {
  beforeEach(() => {
    mockGetContracts.mockReturnValue({
      token: {
        decimals: jest.fn().mockResolvedValue(18),
        symbol: jest.fn().mockResolvedValue('RWA'),
      } as any,
      treasury: {
        previewDeposit: jest.fn().mockResolvedValue(TOKENS_FOR_1_ETH),
      } as any,
      provider: {} as any,
    });
  });

  it('returns expected token amount for a valid ETH deposit', async () => {
    const res = await request(app).get('/preview?amount=1');

    expect(res.status).toBe(200);
    expect(res.body.ethAmount).toBe('1');
    expect(res.body.tokensToMint).toBe(TOKENS_FOR_1_ETH.toString());
    expect(res.body.symbol).toBe('RWA');
    expect(res.body.formatted).toBeDefined();
  });

  it('returns 400 when amount param is missing', async () => {
    const res = await request(app).get('/preview');

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/amount/i);
  });

  it('returns 400 for a non-numeric amount', async () => {
    const res = await request(app).get('/preview?amount=abc');

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/invalid amount/i);
  });

  it('returns 400 for a zero amount', async () => {
    const res = await request(app).get('/preview?amount=0');

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/greater than 0/i);
  });

  it('returns 500 when the contract call fails', async () => {
    mockGetContracts.mockReturnValue({
      token: { decimals: jest.fn(), symbol: jest.fn() } as any,
      treasury: {
        previewDeposit: jest.fn().mockRejectedValue(new Error('RPC error')),
      } as any,
      provider: {} as any,
    });

    const res = await request(app).get('/preview?amount=1');

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('Failed to preview deposit');
  });
});
