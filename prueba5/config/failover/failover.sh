#!/bin/bash

set -e

# ==================================================
# Configuración
# ==================================================

# Contenedores Docker
MASTER_CONTAINER="mysql-master"
SLAVE1_CONTAINER="mysql-slave1"
SLAVE2_CONTAINER="mysql-slave2"

# Hostnames que conoce ProxySQL
MASTER_HOST="master"
SLAVE1_HOST="slave1"
SLAVE2_HOST="slave2"

MYSQL_USER="root"
MYSQL_PASSWORD="Lauta"

FAILOVER_DIR="$(dirname "$0")"

# ==================================================
# Función para comprobar MySQL
# ==================================================

check_mysql() {
    local SERVER="$1"

    docker exec "$SERVER" \
        mysqladmin ping \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        --silent >/dev/null 2>&1
}

# ==================================================
# Inicio
# ==================================================

echo "======================================"
echo "       MySQL Failover Manager"
echo "======================================"

# ==================================================
# 1. Comprobar MASTER
# ==================================================

echo "[1/5] Comprobando master..."

if check_mysql "$MASTER_CONTAINER"; then
    echo "Master disponible."
    echo "No es necesario realizar failover."
    exit 0
fi

echo "Master NO disponible."
echo "Iniciando failover..."

# ==================================================
# 2. Elegir servidor para promocionar
# ==================================================

echo "[2/5] Buscando candidato..."

NEW_MASTER_CONTAINER=""
NEW_MASTER_HOST=""

if check_mysql "$SLAVE1_CONTAINER"; then

    NEW_MASTER_CONTAINER="$SLAVE1_CONTAINER"
    NEW_MASTER_HOST="$SLAVE1_HOST"

    echo "Slave1 disponible. Será promocionado."

elif check_mysql "$SLAVE2_CONTAINER"; then

    NEW_MASTER_CONTAINER="$SLAVE2_CONTAINER"
    NEW_MASTER_HOST="$SLAVE2_HOST"

    echo "Slave1 no disponible."
    echo "Slave2 disponible. Será promocionado."

else

    echo "ERROR: No hay ningún slave disponible."
    exit 1

fi

# Guardamos el hostname del nuevo master
export NEW_MASTER="$NEW_MASTER_HOST"

# ==================================================
# 3. Promocionar nuevo MASTER
# ==================================================

echo "[3/5] Promocionando $NEW_MASTER_CONTAINER..."

docker exec -i "$NEW_MASTER_CONTAINER" \
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
    < "$FAILOVER_DIR/promote.sql"

echo "Promoción completada."

# ==================================================
# 4. Configurar replicación
# ==================================================

echo "[4/5] Configurando replicación..."

# Configurar el usuario replica en el nuevo master

echo "Configurando usuario de replicación en $NEW_MASTER_CONTAINER..."

docker exec -i "$NEW_MASTER_CONTAINER" \
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
    < "$FAILOVER_DIR/configure-replica.sql"

echo "Usuario replica configurado."

# --------------------------------------------------
# Si slave1 fue promovido, slave2 pasa a replicar
# desde slave1.
# --------------------------------------------------

if [ "$NEW_MASTER_CONTAINER" = "$SLAVE1_CONTAINER" ]; then

    echo "Configurando slave2 para replicar desde slave1..."

    envsubst '${NEW_MASTER}' \
        < "$FAILOVER_DIR/reconfigure-replica.sql" \
        | docker exec -i "$SLAVE2_CONTAINER" \
            mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"

    echo "Slave2 ahora replica desde slave1."

# --------------------------------------------------
# Si slave2 fue promovido, slave1 pasa a replicar
# desde slave2.
# --------------------------------------------------

elif [ "$NEW_MASTER_CONTAINER" = "$SLAVE2_CONTAINER" ]; then

    echo "Configurando slave1 para replicar desde slave2..."

    envsubst '${NEW_MASTER}' \
        < "$FAILOVER_DIR/reconfigure-replica.sql" \
        | docker exec -i "$SLAVE1_CONTAINER" \
            mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"


    echo "Slave1 ahora replica desde slave2."

fi

# ==================================================
# 5. Actualizar ProxySQL
# ==================================================

echo "[5/5] Actualizando ProxySQL..."

export NEW_MASTER="$NEW_MASTER_HOST"
export OLD_MASTER="$MASTER_HOST"

envsubst '${NEW_MASTER} ${OLD_MASTER}' \
    < "$FAILOVER_DIR/proxysql-failover.sql" \
    | docker exec -i proxysql \
        mysql -usetup -psetup123 -h127.0.0.1 -P6032

echo "ProxySQL actualizado."

# ==================================================
# 6. Reincorporar antiguo MASTER
# ==================================================

echo "[6/6] Reincorporando antiguo master..."

if check_mysql "$MASTER_CONTAINER"; then

    echo "Antiguo master disponible."
    echo "Configurándolo para replicar desde $NEW_MASTER_HOST..."

    "$FAILOVER_DIR/rejoin.sh" \
        "$MASTER_CONTAINER" \
        "$NEW_MASTER_HOST"

else

    echo "Antiguo master todavía no está disponible."
    echo "Se reincorporará cuando vuelva a estar disponible."

fi

# ==================================================
# Fin
# ==================================================

echo "======================================"
echo "       FAILOVER COMPLETADO"
echo "======================================"
echo "Nuevo master: $NEW_MASTER_HOST"
echo "======================================"
