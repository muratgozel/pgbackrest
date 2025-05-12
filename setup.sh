#!/usr/bin/env bash

apt install -y pgbackrest

mkdir -p -m 770 /var/log/pgbackrest
chown postgres:postgres /var/log/pgbackrest
mkdir -p -m 770 /var/spool/pgbackrest
chown -R postgres:postgres /var/spool/pgbackrest
mkdir -p /etc/pgbackrest
mkdir -p /etc/pgbackrest/conf.d

if [ ! -f /etc/pgbackrest/pgbackrest.conf ]; then
  if [ -f ./.env ]; then
    eval "$(./shdotenv -e ./.env || echo "exit $?")"
  fi

  missing_env_vars=""

  for var in CIPHER_PASS S3_BUCKET S3_ENDPOINT S3_KEY S3_SECRET S3_REGION; do
    if [ -z "${!var+x}" ]; then
      missing_env_vars="$missing_env_vars $var"
    fi
  done
  if [ -n "$missing_env_vars" ]; then
    echo "Missing environment variables: $missing_env_vars"
    exit 1
  fi

  sudo cat ./pgbackrest.conf.template | envsubst | sudo tee /etc/pgbackrest/pgbackrest.conf > /dev/null
fi

chmod 640 /etc/pgbackrest/pgbackrest.conf
chown postgres:postgres /etc/pgbackrest/pgbackrest.conf
sudo -u postgres pgbackrest

pgconf=/etc/postgresql/17/main/postgresql.conf
echo "archive_mode = on" >> $pgconf
echo "archive_command = 'pgbackrest --stanza=app archive-push %p'" >> $pgconf

sudo -u postgres pgbackrest --stanza=app --pg1-port=5432 --log-level-console=info --config=/etc/pgbackrest/pgbackrest.conf stanza-create
service postgresql restart
sleep 6
sudo -u postgres pgbackrest --stanza=app --pg1-port=5432 --log-level-console=info --config=/etc/pgbackrest/pgbackrest.conf check
pgbackrest_check_result=$?

if [ $pgbackrest_check_result -ne 0 ]; then
  echo "pgbackrest check failed."
  exit $pgbackrest_check_result
fi

echo "pgbackrest installed successfully."
