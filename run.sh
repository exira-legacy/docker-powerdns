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

if [[ "x"$WEBSERVER_API_PASSWORD == "x" ]]; then
    export WEBSERVER_API_PASSWORD="$WEBSERVER_PASSWORD"
fi

if [[ "x"$PDNS_LOCALADDRESS == "x" ]]; then
    export PDNS_LOCALADDRESS='0.0.0.0'
fi

if [[ "x"$PDNS_PORT == "x" ]]; then
    export PDNS_PORT='5300'
fi

# Initialising database
if [[ "x"$MYSQL_USER != "x" && "x"$MYSQL_PASSWORD != "x" && "x"$MYSQL_DATABASE != "x" ]]; then
    echo >&2 "Checking for previous database init"
    if [ ! -f /.pdns-db-init ]; then
        sleep 5
        echo >&2 "Previous database init not detected. Parameters detected"

        export PARAM_MYSQLDBOK=`mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="SHOW DATABASES;"|grep -o "${MYSQL_DATABASE}"`

        if [ "$PARAM_MYSQLDBOK" != "$MYSQL_DATABASE" ]; then
            echo >&2 "Failed to connect to Database"
            exit 1
        fi

        echo >&2 "Initialising DB"
        sed -i -e "s:\[dbname\]:${MYSQL_DATABASE}:g" /pdns.sql
        mysql --host=$MYSQL_HOST --port=${MYSQL_PORT} --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE < /pdns.sql
        sleep 4
        touch /.pdns-db-init
    fi
fi

# Basic settings
export PARAMS="--no-config --daemon=no --version-string=exira --setuid=pdns --setgid=pdns"

# Network settings
export PARAMS="$PARAMS --local-address=$PDNS_LOCALADDRESS --local-port=$PDNS_PORT --allow-recursion=0.0.0.0/0"

# SOA settings
export PARAMS="$PARAMS --default-soa-name=$PDNS_SOA_NAME --default-soa-mail=$PDNS_SOA_MAIL --soa-minimum-ttl=3600 --soa-refresh-default=10800 --soa-retry-default=3600"

if [[ "x"$PDNS_IPRANGE != "x" ]]; then
    export PARAMS="$PARAMS --allow-axfr-ips=$PDNS_IPRANGE --only-notify=$PDNS_IPRANGE"
fi

if [[ "x"$MODE_MASTER != "x" ]]; then
    export PARAMS="$PARAMS --master=yes --slave=no --disable-axfr=no"
fi

if [[ "x"$MODE_SLAVE != "x" ]]; then
    export PARAMS="$PARAMS --master=no --slave=yes --disable-axfr=yes --slave-cycle-interval=60"
fi

if [[ "x"$MYSQL_USER != "x" && "x"$MYSQL_PASSWORD != "x" && "x"$MYSQL_DATABASE != "x" ]]; then
    export PARAMS="$PARAMS --launch=gmysql --gmysql-host=$MYSQL_HOST --gmysql-port=$MYSQL_PORT --gmysql-user=$MYSQL_USER --gmysql-password=$MYSQL_PASSWORD --gmysql-dbname=$MYSQL_DATABASE"
fi

if [[ "x"$WEBSERVER != "x" ]]; then
    export PARAMS="$PARAMS --webserver=yes --experimental-json-interface=yes --webserver-address=$WEBSERVER_ADDRESS --webserver-port=$WEBSERVER_PORT --webserver-password=$WEBSERVER_PASSWORD --experimental-api-key=$WEBSERVER_API_PASSWORD"
fi

if [[ "x"$MODE_SLAVE != "x" && "x"$MODE_BIND != "x" ]]; then
    mkdir -p /var/lib/powerdns/zones
    touch /var/lib/powerdns/named-superslave.conf
    chown -R pdns:pdns /var/lib/powerdns

    mkdir -p /etc/powerdns
    cp /named.conf-slave /etc/powerdns/named.conf
    chown -R pdns:pdns /etc/powerdns

    export PARAMS="$PARAMS --launch=bind --bind-config=/etc/powerdns/named.conf --bind-supermasters=/etc/powerdns/supermasters.conf --bind-supermaster-config=/var/lib/powerdns/named-superslave.conf --bind-supermaster-destdir=/var/lib/powerdns/zones"
    echo "$SUPERMASTER_1 ns1" > /etc/powerdns/supermasters.conf

    if [[ "x"$SUPERMASTER_2 != "x" ]]; then
        echo "$SUPERMASTER_2 ns2" >> /etc/powerdns/supermasters.conf
    fi

    if [[ "x"$SUPERMASTER_3 != "x" ]]; then
        echo "$SUPERMASTER_3 ns3" >> /etc/powerdns/supermasters.conf
    fi

    if [[ "x"$SUPERMASTER_4 != "x" ]]; then
        echo "$SUPERMASTER_4 ns4" >> /etc/powerdns/supermasters.conf
    fi
fi

# Run
exec /usr/sbin/pdns_server $PARAMS
