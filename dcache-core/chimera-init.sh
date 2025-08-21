chimera <<EOF
mkdir /data
writetag /data OSMTemplate "StoreName test"
writetag /data sGroup REPLICA
writetag /data AccessLatency ONLINE
chown 1000:1000 /data
exit
EOF