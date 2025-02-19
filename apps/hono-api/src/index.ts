import { log } from '@repo/logger'

import { createServer } from './server'

const port = 5001 // TODO: make this dynamic
const server = createServer()
log(`api running on ${port}`)

export default {
  port: port,
  fetch: server.fetch,
}
