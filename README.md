## Requisitos minimos:

- Docker version 29.6.1, build 8900f1d

- Node v22.21.0

- NPM 10.9.4

## ¿ Cual es el fin de esta investigacion ?

- Hacer un sistema de Replication con MySQL, utilizando la configuración de Master Slave con tres nodos. Donde el intermediario es un Wrapper hecho con SQL Router o ProxySQL. Ademas integrando un sistema de Failover y de rejoin.


## ¿ Que objetivo tiene cada prueba ?

- Prueba1: Conectar una base de datos a node.js y usando los metodos de app.js poder hacer las funciones de un CRUD.

- Prueba2: Crear tres servidores MySQL, cada uno en un docker compose. Y de replicar la configuración Master Slave.

- Prueba3: Crear 3 servidores MySQL con un docker compose, con la configuración de Master Slave, y que de intermediario entre la API y el máster haya un Wrapper hecho con ProxySQL.

- Prueba4: Replicar lo anteriormente hecho en la prueba 3, pero agregarle un sistema de failover y de rejoin.

## Como probar cada prueba: 

Prueba1: 
1) Primero levantar la imagen de docker con el servidor MySQL: 

```bash
docker run -d --name db1 -e MYSQL_ROOT_PASSWORD=Lauta -e MYSQL_DATABASE=Hola -p 3306:3306 mysql:8.0.
```

2) Dentro del proyecto instalar ‘mysql2’:

```bash
npm i mysql2
```

3) En app.js correr primero la funcion createTableProductos().

4) Despues hacer un probra las demas funciones.

Prueba2: 
1) En una terminal ir prueba3/mysql-replicacion y hacer: 

```bash
docker compose up
```

2) Ir hacia prueba3/JS/Apps donde esta cada interfaz de cada base de datos. En la appMaster.js estan todas las operaciones disponibles y en las demas solo las de tipo "SELECT".

Prueba3:
1) Ir a mysql-replication/ hacer y esperar hasta que se termine de configurar:

```bash
docker compose up
```


2) Ir a JS/Apps y en otra terminal ejecutar para comunicarte con el Wrapper:

```bash 
node wrapperApp.js
```

Extra: Si queres ver como estan los grupos del Wrapper podes usar este comando:

```bash
docker exec -it proxysql \
mysql -uadmin -padmin -h127.0.0.1 -P6032 \
-e "SELECT hostgroup, srv_host, srv_port, status, Queries FROM stats_mysql_connection_pool;"
```

Prueba4:
1) Ir a config/ y ejecutar:

```bash
docker compose up
```

2) Y usar el wrapper de la misma manera que en la prueba 3.

Extra: Para poder ver en tiempo real el monitor del failover y el rejoin usa el siguiente comando:

```bash
Docker compose logs -f monitor
```

 

  