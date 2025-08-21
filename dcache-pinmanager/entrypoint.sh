#!/bin/bash
sleep 60

dcache database update

dcache start pinManagerDomain

tail -f /var/log/dcache/pinManagerDomain.log