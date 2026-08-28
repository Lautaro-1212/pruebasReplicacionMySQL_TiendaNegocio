import { pool } from '../dbs/wrapper.js'

const insertProducts = async (producto) => {
  try{
    const result = await pool.query("INSERT INTO productos(nombre) " + "VALUES (?)", [producto]);
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
    const [result] = await pool.query(`SELECT nombre FROM productos`)
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

insertProducts()