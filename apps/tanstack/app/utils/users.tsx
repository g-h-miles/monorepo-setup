export type User = {
  id: number
  name: string
  email: string
}

const PROD_URL = import.meta.env.PROD_URL || 'https://tanstack.mlcr.us'
export const DEPLOY_URL = import.meta.env.PROD
  ? PROD_URL
  : 'http://localhost:3004'
