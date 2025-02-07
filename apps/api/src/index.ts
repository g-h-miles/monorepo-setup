import { log } from '@repo/logger';
import { createServer } from './server';

const port = process.env.PORT || 5001;
const server = createServer();
log(`api running on ${port}`);

export default {
  port: port,
  fetch: server.fetch,
};
