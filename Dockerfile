FROM exira/base:latest

MAINTAINER exira.com <info@exira.com>

#ARG CONTAINER_UID=1002
#ARG CONTAINER_GID=1002

#ENV CONTAINER_USER=pdns \
#    CONTAINER_GROUP=pdns

RUN \
    # Enable alpine testing
    echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories && \

    # Install build and runtime packages
    runtime_pkgs="mysql-client musl bash boost-program_options@edge boost-serialization@edge pdns@testing pdns-backend-mysql@testing" && \
    apk update && \
    apk upgrade && \
    apk --update --no-cache add ${runtime_pkgs} && \

    # add pdns user
    #mkdir -p /home/${CONTAINER_USER} && \
    #addgroup -g $CONTAINER_GID -S ${CONTAINER_GROUP} && \
    #adduser -u $CONTAINER_UID  -S -D -G ${CONTAINER_GROUP} -h /home/${CONTAINER_USER} -s /bin/sh ${CONTAINER_USER} && \
    #chown -R ${CONTAINER_USER}:${CONTAINER_GROUP} /home/${CONTAINER_USER} && \

    # other clean up
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    rm -rf /var/log/*

ADD pdns.sql /pdns.sql

ADD run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 8053

CMD ["/run.sh"]
