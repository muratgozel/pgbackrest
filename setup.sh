#!/usr/bin/env bash

apt install -y pgbackrest

mkdir -p -m 770 /var/log/pgbackrest
chown postgres:postgres /var/log/pgbackrest
mkdir -p -m 770 /var/spool/pgbackrest
chown -R postgres:postgres /var/spool/pgbackrest
mkdir -p /etc/pgbackrest
mkdir -p /etc/pgbackrest/conf.d
touch /etc/pgbackrest/pgbackrest.conf
chmod 640 /etc/pgbackrest/pgbackrest.conf
chown postgres:postgres /etc/pgbackrest/pgbackrest.conf
sudo -u postgres pgbackrest

pgconf=/etc/postgresql/17/main/postgresql.conf
echo "archive_mode = on" >> $pgconf
echo "archive_command = 'pgbackrest --stanza=app archive-push %p'" >> $pgconf

echo "pgbackrest installed successfully."
