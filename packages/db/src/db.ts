// Use a dynamic import approach for Bun's SQL
let sql: any

try {
  // Try to import Bun's SQL module
  const { SQL } = require('bun')

  console.log('Initializing database connection with Bun SQL...')
  sql = new SQL(
    'postgres://postgres:F6GxFia2Pnu74X61MopMEGrYCSJ78M3M1HHCS2tk9svdJILu6eamL6mJ13Od9deS@milescreative-s1:5432/postgres'
  )

  sql.options.onconnect = () => {
    console.log('Connected to database')
  }

  sql.options.onclose = () => {
    console.log('Connection closed')
  }
} catch (error) {
  console.log('Bun SQL not available, using mock implementation')
  // Provide a mock implementation for build environments
  sql = {
    query: async () => {
      console.warn('Using mock SQL implementation - only for build time')
      return []
    },
    // Add other methods as needed
  }
}

export default sql
