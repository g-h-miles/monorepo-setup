import { SQL } from 'bun'

console.log('trying...')
const sql = new SQL(
  'postgres://postgres:F6GxFia2Pnu74X61MopMEGrYCSJ78M3M1HHCS2tk9svdJILu6eamL6mJ13Od9deS@milescreative-s1:5432/postgres'
)

sql.options.onconnect = () => {
  console.log('Connected to database')
}

sql.options.onclose = () => {
  console.log('Connection closed')
}

export default sql
