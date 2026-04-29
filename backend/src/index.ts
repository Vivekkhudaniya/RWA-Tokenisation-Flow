import app from './app';
import { config } from './config';

app.listen(config.port, () => {
  console.log(`RWA Backend listening on http://localhost:${config.port}`);
  console.log('Endpoints:');
  console.log(`  GET /balance/:address`);
  console.log(`  GET /preview?amount=<ETH>`);
  console.log(`  GET /transactions/:address`);
});
