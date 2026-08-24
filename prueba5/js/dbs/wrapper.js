// db.js
import { createPool } from 'mysql2/promise'

export const pool = createPool({
  host: 'localhost',
  port: 6033,
  user: 'app',
  password: 'app123',
  database: 'tienda',
});