import redis from '../redis/redis.js';
import { pool } from '../dbs/wrapper.js';

let exitosos = 0;
let fallidos = 0;
let reintentos = 0;
let procesando = 0;
let recibidos = 0;
//let errorForzado = false;

console.log('Worker iniciado');


// ==============================
// RESUMEN CADA 5 SEGUNDOS
// ==============================

setInterval(async () => {

    try {

        const pendientes = await redis.lLen('insert_queue');

        console.log('\n========== ESTADO WORKER ==========');
        console.log('INSERT exitosos:', exitosos);
        console.log('INSERT fallidos:', fallidos);
        console.log('Reintentos:', reintentos);
        console.log('Procesando actualmente:', procesando);
        console.log('Pendientes en Redis:', pendientes);
        console.log('Operaciones recibidas por Worker:', recibidos);
        console.log('===================================\n');

    } catch (error) {

        console.error(
            'Error obteniendo estado de Redis:',
            error.message
        );

    }

}, 5000);


// ==============================
// WORKER
// ==============================

while (true) {

    try {

        const resultado = await redis.blPop(
            'insert_queue',
            0
        );

        recibidos++;

        const producto = JSON.parse(resultado.element);

        procesando++;

        try {

            if (producto.producto === 'FORZAR_ERROR' && producto.errorForzado) {

                producto.errorForzado = false;

                throw new Error('Error de prueba');

            }

            await pool.query(
                'INSERT INTO productos(nombre) VALUES (?)',
                [producto.producto]
            );

            exitosos++;

        } catch (error) {

            fallidos++;
            reintentos++;

            console.error(
                '❌ INSERT fallido. Reintentando:',
                producto.producto
            );

            await redis.rPush(
                'insert_queue',
                JSON.stringify(producto)
            );

            await new Promise(resolve => {
                setTimeout(resolve, 1000);
            });

        } finally {

            procesando--;

        }

    } catch (error) {

        console.error(
            '❌ Error del Worker:',
            error.message
        );

    }

}
