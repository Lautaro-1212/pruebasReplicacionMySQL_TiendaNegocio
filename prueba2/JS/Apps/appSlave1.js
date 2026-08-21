import { pool } from '../DBs/db2.js';

const getProductsFromSlave1 = async () => {
  try{
    const [result] = await pool.query(`SELECT id, nombre, precio FROM productos`)
    console.table(result);
  } catch(error){
    console.error(error)
  }
}

getProductsFromSlave1();