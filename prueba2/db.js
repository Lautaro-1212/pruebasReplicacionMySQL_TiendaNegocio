// db.js
import { createPool }from 'mysql2/promise'

// Create the connection pool
export const pool = createPool({
  host: '10.56.134.28',
  port:'3306',
  user: 'root',
  password: 'Lauta',
  database: 'Hola',
});