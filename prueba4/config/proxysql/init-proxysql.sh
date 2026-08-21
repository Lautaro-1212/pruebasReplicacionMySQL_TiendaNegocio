#!/bin/bash

set -e

echo "Esperando ProxySQL..."

until mysql \
    -h proxysql \
    -usetup \
    -psetup123 \
    -P6032 \
    -e "SELECT 1" >/dev/null 2>&1
do
    echo "ProxySQL todavía no está listo..."
    sleep 2
done

echo "ProxySQL listo."

echo "Aplicando configuración de ProxySQL..."

mysql \
    -h proxysql \
    -usetup \
    -psetup123 \
    -P6032 \
    < /setup/init-proxysql.sql

echo "ProxySQL configurado correctamente."