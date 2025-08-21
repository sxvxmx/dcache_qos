#!/bin/bash
sleep 20

echo "dCache pool..."
mkdir -p /srv/dcache/
dcache pool create /srv/dcache/${POOL_NAME}1 ${POOL_NAME}1 poolsDomain
dcache pool create /srv/dcache/${POOL_NAME}2 ${POOL_NAME}2 poolsDomain
dcache pool create /srv/dcache/${POOL_NAME}3 ${POOL_NAME}3 poolsDomain

dcache start

tail -f /var/log/dcache/poolsDomain.log