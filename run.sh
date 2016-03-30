#!/bin/bash
set -e

# Setting default values
if [[ "x"$MYSQL_HOST == "x" ]]; then
    export MYSQL_HOST='db'
fi

if [[ "x"$MYSQL_PORT == "x" ]]; then
    export MYSQL_PORT='3306'
fi

if [[ "x"$WEBSERVER_ADDRESS == "x" ]]; then
    export WEBSERVER_ADDRESS='0.0.0.0'
fi

if [[ "x"$WEBSERVER_PORT == "x" ]]; then
    export WEBSERVER_PORT='8000'
fi

if [[ "x"$PDNS_LOCALADDRESS == "x" ]]; then
    export PDNS_LOCALADDRESS='0.0.0.0'
fi

if [[ "x"$PDNS_PORT == "x" ]]; then
    export PDNS_PORT='5300'
fi

if [[ "x"$PDNS_IPRANGE == "x" ]]; then
    export PDNS_IPRANGE='127.0.0.0/8'
fi

# Initialising database
if [[ "x"$MYSQL_USER != "x" && "x"$MYSQL_PASSWORD != "x" && "x"$MYSQL_DATABASE != "x" ]]; then
    if [[ ! -x /.pdns-db-init ]]; then
        sleep 5
        touch /.pdns-db-init
        echo >&2 "Parameters detected"

        export PARAM_MYSQLOK=`mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="SHOW DATABASES;"|grep -o "Database"`
        export PARAM_MYSQLDBOK=`mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="SHOW DATABASES;"|grep -o "${MYSQL_DATABASE}"`

        if [ "$PARAM_MYSQLOK" != "Database" ]; then
            echo >&2 "Failed to connect to Database"
            exit 1
        fi

        if [[ "$PARAM_MYSQLDBOK" != "$MYSQL_DATABASE" ]]; then
            echo >&2 "Initialising DB"
            sed -i -e "s:\[dbname\]:${MYSQL_DATABASE}:g" /pdns.sql
            mysql --host=$MYSQL_HOST --port=${MYSQL_PORT} --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE < /pdns.sql
            sleep 4
        fi
    fi
fi

# Basic config
export PARAMS="--no-config --master --daemon=no --setuid=pdns --setgid=pdns --local-address=$PDNS_LOCALADDRESS --local-port=$PDNS_PORT --allow-axfr-ips=$PDNS_IPRANGE"

if [[ "x"$MYSQL_USER != "x" && "x"$MYSQL_PASSWORD != "x" && "x"$MYSQL_DATABASE != "x" ]]; then
    export PARAMS="$PARAMS --launch=gmysql --gmysql-host=$MYSQL_HOST --gmysql-port=$MYSQL_PORT --gmysql-user=$MYSQL_USER --gmysql-password=$MYSQL_PASSWORD --gmysql-dbname=$MYSQL_DATABASE"
fi

if [[ "x"$WEBSERVER != "x" ]]; then
    export PARAMS="$PARAMS --webserver=y  --webserver-address=$WEBSERVER_ADDRESS --webserver-port=$WEBSERVER_PORT --webserver-password=$WEBSERVER_PASSWORD"
fi

# Run
exec /usr/sbin/pdns_server $PARAMS
