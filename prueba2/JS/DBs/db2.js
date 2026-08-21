// db.js
import { createPool }from 'mysql2/promise'

// Create the connection pool
export const pool = createPool({
  host: 'localhost',
  port:'3307',
  user: 'root',
  password: 'Lauta',
  database: 'tienda',
});