import express from 'express';
import balanceRouter from './routes/balance';
import previewRouter from './routes/preview';
import transactionsRouter from './routes/transactions';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/balance', balanceRouter);
app.use('/preview', previewRouter);
app.use('/transactions', transactionsRouter);

export default app;
