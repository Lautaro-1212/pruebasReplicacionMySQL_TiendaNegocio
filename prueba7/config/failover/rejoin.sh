#!/bin/bash

set -e

# ==================================================
# Configuración
# ==================================================

MYSQL_USER="root"
MYSQL_PASSWORD="Lauta"

PROXYSQL_USER="admin"
PROXYSQL_PASSWORD="admin"

PROXYSQL_CONTAINER="proxysql"

NODES=(
    "mysql-master"
    "mysql-slave1"
    "mysql-slave2"
)

# ==================================================
# Obtener master actual desde ProxySQL
# ==================================================

echo "======================================"
echo "       MySQL Rejoin Manager"
echo "======================================"

echo "[1/3] Detectando master actual..."

CURRENT_MASTER=$(
    docker exec "$PROXYSQL_CONTAINER" \
        mysql -u"$PROXYSQL_USER" \
        -p"$PROXYSQL_PASSWORD" \
        -h127.0.0.1 \
        -P6032 \
        -N -B \
        -e "
            SELECT hostname
            FROM runtime_mysql_servers
            WHERE hostgroup_id = 10
              AND status = 'ONLINE'
            LIMIT 1;
        "
)

if [ -z "$CURRENT_MASTER" ]; then
    echo "ERROR: No se pudo determinar el master actual."
    exit 1
fi

echo "Master actual: $CURRENT_MASTER"

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
# Función para obtener Source_Host
# ==================================================

get_source_host() {
    local SERVER="$1"

    docker exec "$SERVER" \
        mysql -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        -N -B \
        -e "
            SHOW REPLICA STATUS;
        " 2>/dev/null |
        awk -F '\t' '
            NR == 1 {
                print $2
            }
        '
}

# ==================================================
# 2. Revisar nodos
# ==================================================

echo ""
echo "[2/3] Revisando nodos..."

for NODE in "${NODES[@]}"; do

    echo ""
    echo "--------------------------------------"
    echo "Nodo: $NODE"

    # --------------------------------------------------
    # Nodo caído
    # --------------------------------------------------

    if ! check_mysql "$NODE"; then
        echo "Estado: NO DISPONIBLE"
        echo "Se omitirá."
        continue
    fi

    # --------------------------------------------------
    # Nodo que es el master actual
    # --------------------------------------------------

    if [ "$NODE" = "mysql-$CURRENT_MASTER" ]; then
        echo "Estado: MASTER ACTUAL"
        echo "No necesita rejoin."
        continue
    fi

    # --------------------------------------------------
    # Obtener source actual
    # --------------------------------------------------

    SOURCE_HOST=$(get_source_host "$NODE")

    echo "Source actual: ${SOURCE_HOST:-NINGUNO}"

    # --------------------------------------------------
    # Ya replica del master actual
    # --------------------------------------------------

    if [ "$SOURCE_HOST" = "$CURRENT_MASTER" ]; then
        echo "Replicación: CORRECTA"
        continue
    fi

    # --------------------------------------------------
    # Necesita reconfiguración
    # --------------------------------------------------

    echo "Replicación: INCORRECTA"
    echo "Reconfigurando $NODE → $CURRENT_MASTER..."

    docker exec -i "$NODE" \
        mysql -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" <<EOF

STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='$CURRENT_MASTER',
    SOURCE_PORT=3306,
    SOURCE_USER='replica',
    SOURCE_PASSWORD='replica123',
    SOURCE_AUTO_POSITION=1;

START REPLICA;

EOF

    echo "Rejoin completado para $NODE."

done

# ==================================================
# Fin
# ==================================================

echo ""
echo "[3/3] Rejoin finalizado."

echo "======================================"
echo "       REJOIN COMPLETADO"
echo "======================================"