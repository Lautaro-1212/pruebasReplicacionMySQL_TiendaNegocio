#!/bin/bash

set -x


echo "Inicio del setup"



echo "Esperando master..."


until mysql -h master -uroot -pLauta -e "SELECT 1" >/dev/null 2>&1

do

    sleep 2

done



echo "Esperando slave1..."


until mysql -h slave1 -uroot -pLauta -e "SELECT 1" >/dev/null 2>&1

do

    sleep 2

done



echo "Esperando slave2..."


until mysql -h slave2 -uroot -pLauta -e "SELECT 1" >/dev/null 2>&1

do

    sleep 2

done



echo "Configurando slave1"



mysql -h slave1 -uroot -pLauta <<EOF

STOP REPLICA;

RESET REPLICA ALL;


CHANGE REPLICATION SOURCE TO

SOURCE_HOST='master',

SOURCE_USER='replica',

SOURCE_PASSWORD='1234',

SOURCE_AUTO_POSITION=1;


START REPLICA;

EOF





echo "Configurando slave2"



mysql -h slave2 -uroot -pLauta <<EOF

STOP REPLICA;

RESET REPLICA ALL;


CHANGE REPLICATION SOURCE TO

SOURCE_HOST='master',

SOURCE_USER='replica',

SOURCE_PASSWORD='1234',

SOURCE_AUTO_POSITION=1;


START REPLICA;

EOF



echo "Replicacion lista"