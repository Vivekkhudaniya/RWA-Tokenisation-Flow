import request from 'supertest';
import app from '../src/app';
import { getContracts } from '../src/contracts';

jest.mock('../src/contracts');

const mockGetContracts = getContracts as jest.MockedFunction<typeof getContracts>;

const VALID_ADDRESS = '0x742d35Cc6634C0532925a3b844Bc454e4438f44e';

const mockDepositLog = {
  transactionHash: '0xabc123def456',
  blockNumber: 200,
  args: [VALID_ADDRESS, 1n * 10n ** 18n, 1000n * 10n ** 18n],
};

const mockWithdrawLog = {
  transactionHash: '0xfed321cba654',
  blockNumber: 150,
  args: [VALID_ADDRESS, 2n * 10n ** 18n],
};

function buildMockTreasury(depositLogs: object[], withdrawLogs: object[]) {
  const queryFilter = jest.fn()
    .mockResolvedValueOnce(depositLogs)
    .mockResolvedValueOnce(withdrawLogs);

  return {
    filters: {
      Deposited: jest.fn().mockReturnValue('deposited-filter'),
      Withdrawn: jest.fn().mockReturnValue('withdrawn-filter'),
    },
    queryFilter,
  };
}

describe('GET /transactions/:address', () => {
  it('returns deposit and withdrawal history sorted newest first', async () => {
    mockGetContracts.mockReturnValue({
      token: {} as any,
      treasury: buildMockTreasury([mockDepositLog], [mockWithdrawLog]) as any,
      provider: {} as any,
    });

    const res = await request(app).get(`/transactions/${VALID_ADDRESS}`);

    expect(res.status).toBe(200);
    expect(res.body.address).toBe(VALID_ADDRESS);
    expect(res.body.transactions).toHaveLength(2);

    // deposit (block 200) should come first — sorted newest first
    expect(res.body.transactions[0].type).toBe('deposit');
    expect(res.body.transactions[0].txHash).toBe('0xabc123def456');
    expect(res.body.transactions[0].tokensMinted).toBe((1000n * 10n ** 18n).toString());

    expect(res.body.transactions[1].type).toBe('withdrawal');
    expect(res.body.transactions[1].txHash).toBe('0xfed321cba654');
  });

  it('returns an empty list when no transactions exist', async () => {
    mockGetContracts.mockReturnValue({
      token: {} as any,
      treasury: buildMockTreasury([], []) as any,
      provider: {} as any,
    });

    const res = await request(app).get(`/transactions/${VALID_ADDRESS}`);

    expect(res.status).toBe(200);
    expect(res.body.transactions).toHaveLength(0);
  });

  it('returns 400 for an invalid address', async () => {
    const res = await request(app).get('/transactions/not-valid');

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Invalid Ethereum address');
  });

  it('returns 500 when the RPC call fails', async () => {
    mockGetContracts.mockReturnValue({
      token: {} as any,
      treasury: {
        filters: {
          Deposited: jest.fn().mockReturnValue({}),
          Withdrawn: jest.fn().mockReturnValue({}),
        },
        queryFilter: jest.fn().mockRejectedValue(new Error('RPC error')),
      } as any,
      provider: {} as any,
    });

    const res = await request(app).get(`/transactions/${VALID_ADDRESS}`);

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('Failed to fetch transactions');
  });
});
