import { pool } from '../dbs/db3.js';

const getProductsFromSlave1 = async () => {
  try{
    const [result] = await pool.query(`SELECT id, nombre, precio FROM productos`)
    console.table(result);
    console.log("Los productos se obtuvieron correctamente desde el Slave 2")
  } catch(error){
    console.error(error)
  }
}

getProductsFromSlave1();