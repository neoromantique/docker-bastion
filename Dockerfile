FROM alpine:3.20

#LABEL maintainer="Mark <mark.binlab@gmail.com>"
LABEL maintainer="David <os.david@gtw.lt>"

ARG HOME=/var/lib/bastion

ARG USER=bastion
ARG GROUP=bastion
ARG UID=4096
ARG GID=4096

ENV HOST_KEYS_PATH_PREFIX="/usr" \
    HOST_KEYS_PATH="/usr/etc/ssh"

COPY --chmod=755 --chown=root:root bastion /usr/sbin/bastion

RUN mkdir -p /var/run/bastion
RUN chown ${UID}:${GID} /var/run/bastion
RUN chmod 755 /var/run/bastion

RUN set -eux; \
    addgroup -S -g ${GID} ${GROUP}; \
    adduser -D -h ${HOME} -s /bin/ash -g "${USER} service" \
    -u ${UID} -G ${GROUP} ${USER}; \
    sed -i "s/${USER}:!/${USER}:*/g" /etc/shadow; \
    \
    apk add --no-cache \
    openssh-server \
    ca-certificates; \
    \
    echo "Welcome to Bastion!" > /etc/motd; \
    mkdir -p ${HOST_KEYS_PATH}; \
    chown -R ${USER}:${GROUP} ${HOST_KEYS_PATH}; \
    chmod 755 ${HOST_KEYS_PATH}; \
    mkdir -p /etc/ssh/auth_principals; \
    echo "bastion" > /etc/ssh/auth_principals/bastion; \
    echo "PidFile /usr/etc/ssh/sshd.pid" >> /etc/ssh/sshd_config; \
    \
    chmod 700 ${HOME}; \
    chown ${USER}:${GROUP} ${HOME}; \
    \
    rm -rf /var/cache/apk/* /tmp/*

USER ${USER}

EXPOSE 22/tcp

VOLUME ["${HOST_KEYS_PATH}"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -z localhost 22 || exit 1

ENTRYPOINT ["/usr/sbin/bastion"]
