// db.js
import { createPool }from 'mysql2/promise'

// Create the connection pool
export const pool = createPool({
  host: '10.56.134.50',
  port:'3306',
  user: 'root',
  password: 'Pedro',
  database: 'db2',
});
