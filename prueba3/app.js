import { pool } from './db.js'

const insertProducts = async () => {
  try{
    const result = await pool.query("INSERT INTO productos(codigo, nombre, precio, stock) " + "VALUES (?, ?, ?, ?)", ["1231", "Pancho", 1231, 1211]);
    console.table(result)
    console.log("Los productos se insertaron correctamente")
  } catch(error){
    console.error(error)
  }
}

const createTableProductos = async () => {
  try{
    const [result] = await pool.query(`
      CREATE TABLE productos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        codigo VARCHAR(50) NOT NULL,
        nombre VARCHAR(100) NOT NULL,
        precio DECIMAL(10,2) NOT NULL,
        stock INT NOT NULL
      )
    `);

    console.table(result)
    console.log("La tabla se creo exitosamente")
  } catch (error) {
    console.error(error)
  }
}

const getProducts = async () => {
  try{
    const [result] = await pool.query(`SELECT id, codigo, nombre, precio, stock FROM productos`)
    console.table(result);
  } catch(error){
    console.error(error)
  }
}

const emptyTable = async () => {
  try{
    const [result] = await pool.query(`DELETE FROM productos`)
    console.table(result);
    console.log("La tabla se vacio exitosamente")
  } catch(error){
    console.error(error)
  }
}

getProducts()