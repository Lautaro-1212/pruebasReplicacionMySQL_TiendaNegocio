#!/bin/bash

set -u

# ==================================================
# Configuración
# ==================================================

CHECK_INTERVAL=5

FAILOVER_SCRIPT="./failover.sh"
REJOIN_SCRIPT="./rejoin.sh"

MYSQL_USER="root"
MYSQL_PASSWORD="Lauta"

# ==================================================
# Funciones
# ==================================================

get_current_master() {

    docker exec mysql-slave1 \
        mysql -uroot -pLauta -N -s \
        -e "SHOW VARIABLES LIKE 'read_only';" 2>/dev/null

}

check_node() {

    local node="$1"

    docker exec "$node" \
        mysqladmin ping -uroot -pLauta \
        --silent >/dev/null 2>&1
}

# ==================================================
# Monitor
# ==================================================

echo "======================================"
echo "       MySQL Cluster Monitor"
echo "======================================"
echo "Intervalo: ${CHECK_INTERVAL}s"
echo "Monitor iniciado."
echo

while true; do

    # ----------------------------------------------
    # 1. Detectar master actual mediante ProxySQL
    # ----------------------------------------------

    MASTER=$(docker exec proxysql \
        mysql -uadmin -padmin -h127.0.0.1 -P6032 -N -s \
        -e "SELECT hostname FROM runtime_mysql_servers WHERE hostgroup_id=10 AND status='ONLINE' LIMIT 1;" \
        2>/dev/null)

    # ----------------------------------------------
    # 2. Si no hay master ONLINE
    # ----------------------------------------------

    if [ -z "$MASTER" ]; then

        echo "[$(date '+%H:%M:%S')] No hay master ONLINE."
        echo "[$(date '+%H:%M:%S')] Ejecutando failover..."

        bash "$FAILOVER_SCRIPT"

        echo "[$(date '+%H:%M:%S')] Failover finalizado."
        echo

        sleep "$CHECK_INTERVAL"
        continue
    fi

    # ----------------------------------------------
    # 3. Comprobar que el master realmente responde
    # ----------------------------------------------

    if ! check_node "mysql-$MASTER"; then

        echo "[$(date '+%H:%M:%S')] Master actual: $MASTER"
        echo "[$(date '+%H:%M:%S')] Master NO disponible."
        echo "[$(date '+%H:%M:%S')] Ejecutando failover..."

        bash "$FAILOVER_SCRIPT"

        echo "[$(date '+%H:%M:%S')] Failover finalizado."
        echo

        sleep "$CHECK_INTERVAL"
        continue
    fi

    # ----------------------------------------------
    # 4. Master OK
    # ----------------------------------------------

    echo "[$(date '+%H:%M:%S')] Master: $MASTER | OK"

    # ----------------------------------------------
    # 5. Revisar reincorporaciones
    # ----------------------------------------------

    bash "$REJOIN_SCRIPT" >/tmp/rejoin.log 2>&1

    if grep -q "Rejoin completado" /tmp/rejoin.log; then
        echo "[$(date '+%H:%M:%S')] Se reincorporó un nodo."
    fi

    sleep "$CHECK_INTERVAL"

done
