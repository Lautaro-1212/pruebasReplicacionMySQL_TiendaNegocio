#!/bin/bash
set -x

echo "Inicio del setup"

echo "Esperando a que el master esté listo..."

until mysql -h master -uroot -pLauta -e "SELECT 1" >/dev/null 2>&1
do
    sleep 2
done

echo "Master listo."

until mysql -h slave1 -uroot -pLauta -e "SELECT 1" >/dev/null 2>&1
do
    sleep 2
done

until mysql -h slave2 -uroot -pLauta -e "SELECT 1" >/dev/null 2>&1
do
    sleep 2
done

echo "Configurando Slave 1..."

mysql -h slave1 -uroot -pLauta <<EOF
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='master',
  SOURCE_USER='replica',
  SOURCE_PASSWORD='1234',
  SOURCE_AUTO_POSITION=1;

START REPLICA;
EOF

echo "Configurando Slave 2..."

mysql -h slave2 -uroot -pLauta <<EOF
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='master',
  SOURCE_USER='replica',
  SOURCE_PASSWORD='1234',
  SOURCE_AUTO_POSITION=1;

START REPLICA;
EOF

echo "Replicación configurada."