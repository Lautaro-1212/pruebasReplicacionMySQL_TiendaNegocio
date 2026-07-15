// Import the promise-based version of mysql2
const mysql = require('mysql2/promise');

async function initializeTable() {
  try {
    // 1. Configure the database connection parameters
    const connection = await mysql.createConnection({
      host: 'localhost',
      port:'3306',
      user: 'root',     // Replace with your MySQL username
      password: 'Lauta', // Replace with your MySQL password
      database: 'Hola'  // Replace with your target database name
    });

    console.log('Connected to the MySQL server successfully.');

    // 2. Define the SQL query to create the table structure
    const createTableQuery = `
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(150) NOT NULL UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    `;

    // 3. Execute the creation query
    await connection.query(createTableQuery);
    console.log('Table "users" was checked/created successfully.');

    // 4. Close the connection stream
    await connection.end();
    
  } catch (error) {
    console.error('An error occurred:', error.message);
  }
}

initializeTable();