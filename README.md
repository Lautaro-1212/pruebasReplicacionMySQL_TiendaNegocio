## Requisitos minimos:

- Docker version 29.6.1, build 8900f1d

- Node v22.21.0

- npm 10.9.4

- npx 10.9.4

## ¿ Cual es el fin de esta investigacion ?

- Hacer un sistema de Replication con MySQL, utilizando la configuración de Master Slave con tres nodos. Donde el intermediario es un Wrapper hecho con SQL Router o ProxySQL. Ademas integrando un sistema de Failover y de rejoin.

## ¿ Que objetivo tiene cada prueba ?

- Prueba1: Conectar una base de datos a node.js y usando los metodos de app.js poder hacer las funciones de un CRUD.

- Prueba2: Crear tres servidores MySQL, cada uno en un docker compose. Y de replicar la configuración Master Slave.

- Prueba3: Crear 3 servidores MySQL con un docker compose, con la configuración de Master Slave, y que de intermediario entre la API y el máster haya un Wrapper hecho con ProxySQL.

- Prueba4: Replicar lo anteriormente hecho en la prueba 3, pero agregarle un sistema de failover y de rejoin.

- Prueba 5: Aplicar lo mismo que lo anterior, pero los métodos de wrapperApp.js hacerlos endpoint con express, y probar la concurrencia con autocannon.

- Prueba 6: Agregar un sistema para que cuando no se pueda hacer un insert lo ponga en una cola y después de unos segundos haga un reintento.
## 

<span style="font-size: 30px">**Como probar cada prueba:**</span>

<span style="font-size: 20px">**ACLARACIONES:**</span>

1) Para ejecutar cualquier comando que este relacionado con Docker, te tenes que para pruebaX/config/

##

<span style="font-size: 25px">**Prueba1:**</span>

1) Ir hacia la carpeta de la prueba1:

```bash
cd prueba1
```

2) Primero levantar la imagen de docker con el servidor MySQL: 

```bash
docker run -d --name db1 -e MYSQL_ROOT_PASSWORD=Lauta -e MYSQL_DATABASE=Hola -p 3306:3306 mysql:8.0.
```

3) Dentro del proyecto instalar ‘mysql2’:

```bash
npm i mysql2
```

4) Ejecutar app.js con: 

5) Probar los diferentes funciones de app.js reemplazar al final del todo la funcion por otra.

##

<span style="font-size: 25px">**Prueba2:**</span>

1) Ir hacia la carpeta de la prueba2

```bash
cd prueba2
```

2) En una terminal ir mysql-replicacion/ y hacer: 

```bash
cd mysql-replicacion
docker compose up
```

3) Ir hacia js/apps donde esta cada interfaz de cada base de datos. En la appMaster.js estan todas las operaciones disponibles y en las demas solo las de tipo. Se puede probar con: 

##

<span style="font-size: 25px">**Prueba3:**</span>

Ir a la prueba:

```bash
cd prueba3
```

Instalar las dependecias:

```bash
npm i
```

Iniciar los servicios:

```bash
docker compose up
```

Esperar hasta ver esta leyendo:

```bash
setup-1 | + echo 'Replicacion lista'
```

Ver si los grupos se armaron correctamente en proxysql:

```bash
docker exec -it proxysql \
mysql -uadmin -padmin -h127.0.0.1 -P6032 \
-e "SELECT hostgroup, srv_host, srv_port, status, Queries FROM stats_mysql_connection_pool;"
```

Para probar si las reglas del proxysql se cumplen, hay que ejecutar wrapperApp.js:

Para poder probar hacer un get para comprobar que llegan a los slaves(hostgroup20), podes ejecutar wrapperApp.js como viene por defecto:

```bash
node wrapperApp.js
```

Luego podes comprobar si llego la consulta con ejecutando el comando para ver los grupos, se deberia de ver algo asi la salida:

```bash
+-----------+----------+----------+--------+---------+
| hostgroup | srv_host | srv_port | status | Queries |
+-----------+----------+----------+--------+---------+
| 10        | master   | 3306     | ONLINE | 0       |
| 20        | slave1   | 3306     | ONLINE | 1       |
| 20        | slave2   | 3306     | ONLINE | 0       |
+-----------+----------+----------+--------+---------+
```

Para poder probar un INSERT tenes que reemplazar el metodo de wrapperApp.js y ejecutar denuevo: 

```js
getProducts() -> insertProducts("Producto de prueba")
```

Y de nuevo ver los grupos, tendrias que ver algo asi:

```bash
+-----------+----------+----------+--------+---------+
| hostgroup | srv_host | srv_port | status | Queries |
+-----------+----------+----------+--------+---------+
| 10        | master   | 3306     | ONLINE | 1       |
| 20        | slave1   | 3306     | ONLINE | 1       |
| 20        | slave2   | 3306     | ONLINE | 0       |
+-----------+----------+----------+--------+---------+
```

##

<span style="font-size: 25px">**Prueba4:**</span>

Ir a la prueba:

```bash
cd prueba4
```

Instalar las dependencias:

```bash 
npm i
```

Iniciar los servicios y esperar unos segundos hasta que ver el monitor:

```bash
docker compose up
```

En una terminal ver los logs en tiempo real del monitor: 

```bash
docker compose logs -f monitor
```

En otra terminal tirar el master para ver como se activa el Failover:

```bash
docker stop mysql-master
```

Deberia aparecer algo asi dentro del monotir:

```bash
monitor-1  | [14:06:30] Master NO disponible.
monitor-1  | [14:06:30] Ejecutando failover...
monitor-1  | ======================================
monitor-1  |        MySQL Failover Manager
monitor-1  | ======================================
monitor-1  | [1/5] Comprobando master...
monitor-1  | Master NO disponible.
monitor-1  | Iniciando failover...
monitor-1  | [2/5] Buscando candidato...
monitor-1  | Slave1 disponible. Será promocionado.
monitor-1  | [3/5] Promocionando mysql-slave1...
monitor-1  | mysql: [Warning] Using a password on the command line interface can be insecure.
monitor-1  | Promoción completada.
monitor-1  | [4/5] Configurando replicación...
monitor-1  | Configurando usuario de replicación en mysql-slave1...
monitor-1  | mysql: [Warning] Using a password on the command line interface can be insecure.
monitor-1  | Usuario replica configurado.
monitor-1  | Configurando slave2 para replicar desde slave1...
monitor-1  | mysql: [Warning] Using a password on the command line interface can be insecure.
monitor-1  | Slave2 ahora replica desde slave1.
monitor-1  | [5/5] Actualizando ProxySQL...
monitor-1  | ProxySQL actualizado.
monitor-1  | [6/6] Reincorporando antiguo master...
monitor-1  | Antiguo master todavía no está disponible.
monitor-1  | Se reincorporará cuando vuelva a estar disponible.
monitor-1  | ======================================
monitor-1  |        FAILOVER COMPLETADO
monitor-1  | ======================================
monitor-1  | Nuevo master: slave1
monitor-1  | ======================================
monitor-1  | [14:06:31] Failover finalizado.
```

Levantar de nuevo el master para ver como se activa el sistema de Rejoin:

```bash 
docker start mysql-master
```

En el monitor tendria que aparecer esto:

```bash
monitor-1  | [14:07:11] Se reincorporó un nodo.
```

## 

<span style="font-size: 25px">**Prueba5:**</span>

Ir a la prueba: 

```bash 
cd prueba5
```

Instalar las dependencias: 

```bash 
npm i
```

Levantar los servicios y esperar unos segundos hasta que ver el monitor: 

```bash 
docker compose up
```

En otra terminal levantar el servidor de Express:

```bash 
cd js/apps
node wrapperApp.js
```

En otra terminal parado en "js/apps" hacer un GET de los productos:

```bash
curl http://localhost:3010/products
```

Hacer un INSERT: 

```bash
curl -X POST http://localhost:3010/insert \
  -H "Content-Type: application/json" \
  -d '{"producto":"prueba3-ejemplo"}'
```

Hacer un DELETE:

```bash
curl -X DELETE http://localhost:3010/empty
```

Probar concurrencia con Autocannon:

```bash
npx autocannon -m POST -H "Content-Type: application/json" -b '{"producto":"pancho"}' -c 10 -a 2000 http://localhost:3010/insert
```

##

<span style="font-size: 25px">**Prueba6:**</span>

Ir a la prueba

```bash
cd prueba6
```

Instalar las dependencias: 

```bash 
npm i
```

Levantar el compose con todos los servicios y esperar unos segundos hasta que ver el monitor:

```bash
docker compose up
```

En otra terminal iniciar el servidor de Express y el Redis:

```bash
cd js/apps
node wrapperApp.js
```

En otra terminal iniciar Worker:

```bash
cd js/workers
node insertWorker.js
```

En otra terminal con Autocannon generar muchos request y generar estadisticas:

```bash
cd js/apps
npx autocannon \
-m POST \
-H "Content-Type: application/json" \
-b '{"producto":"pancho"}' \
-c 500 \
-d 20 \
-j \
http://localhost:3010/insert > resultado.json
```

En otra terminal parar el master para que se promueva a otro mientras se estan haciendo insert del Autocannon:

```bash
docker stop mysql-master
```

Espera unos segundos hasta que el Worker deje de actualizar. Una vez termine, tira una request mas usando curl o Postman, para que se actualize devuelta el Worker:

```bash
curl -X POST http://localhost:3010/insert \
  -H "Content-Type: application/json" \
  -d '{"producto":"prueba-worker"}'
```

En otra terminal podes mirar cuantos request llegaron exitosamente segun Autocannon con este comando:

```bash
jq '.requests.sent' resultado.json
```

Tambien podes ver cuantos registros quedaron en la tabla haciendo:

```bash
docker exec -it proxysql \
mysql -uapp -papp123 -h127.0.0.1 -P6033 \
-e "USE tienda; SELECT COUNT(*) AS total FROM productos;"
```

Con todo esto comproba que todas los inserts llegaron exitosamente.
