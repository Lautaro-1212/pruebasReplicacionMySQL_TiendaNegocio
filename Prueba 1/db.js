// db.js
const mysql = require('mysql2/promise');

// Create the connection pool
const pool = mysql.createPool({
  host: '3306',
  user: 'root',
  password: 'Lauta',
  database: 'bas1',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;
  