FROM node:12.16.0-alpine as base

LABEL maintainer "Igal Dahan <igald@anyvision.co>"

RUN apk update \
    && apk add --no-cache \
       ca-certificates curl wget lsof \
       vim git less busybox-extras \
       net-tools iftop htop nethogs \
       unzip wget python gcc \
       libc-dev bash make g++

# This is the release of Consul to pull in.
ENV CONSUL_VERSION=1.4.3

# This is the location of the releases.
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

# Add consul agent
RUN export CONSUL_VERSION=1.4.3 \
    && wget "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && unzip $PWD/consul_${CONSUL_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm /$PWD/consul_${CONSUL_VERSION}_linux_amd64.zip

    #&& export CONSUL_CHECKSUM=8806fdaace8cfca3a0d49a2ef1ea03e5d2b63ff1f3fbe9909dc190637195df5c \
    #&& curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    #&& echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \

# INSTALL GOSU
#ENV GOSU_VERSION 1.11
#RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
#    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
#    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
#    \
#    # verify the signature
#    export GNUPGHOME="$(mktemp -d)"; \
#    # for flaky keyservers, consider https://github.com/tianon/pgp-happy-eyeballs, ala https://github.com/docker-library/php/pull/666
#    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
#    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
#    command -v gpgconf && gpgconf --kill all || :; \
#    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
#    \
#    chmod +x /usr/local/bin/gosu; \
#    # verify that the binary works
#    gosu --version; \
#    gosu nobody true

# Install envconsul
RUN wget https://releases.hashicorp.com/envconsul/0.6.1/envconsul_0.6.1_linux_amd64.zip \
    && unzip envconsul_0.6.1_linux_amd64.zip \
    && rm envconsul_0.6.1_linux_amd64.zip \
    && mv $PWD/envconsul /usr/local/bin

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && rm dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz


COPY package.json .

## ---- Dependencies ----
FROM base AS dependencies
# install node packages

## Copy Artifact certificate for login
COPY .npmrc /.npmrc

# Copy source code into the container
COPY --chown=node ./ ./source-code
WORKDIR ./source-code

RUN npm config set registry https://anyvision.jfrog.io/anyvision/api/npm/npm/
RUN PYTHON=/usr/bin/python
RUN npm ci --verbose
RUN npm run build
# Delete the unneeded src folder
# RUN rm -rf ./src
# Use npm ci to delete the old node_modules and install only production
RUN npm --verbose ci --production
RUN rm .npmrc

# ---- Release ----
FROM node:12.16.0-alpine AS release

RUN apk update \
    && apk add --no-cache \
       curl su-exec\
       vim git less busybox-extras \
       net-tools iftop htop nethogs \
       unzip wget \
       bash

# INSTALL NODE MODULES
ENV APP_DIR /home/node/RENAMEIT
WORKDIR $APP_DIR

RUN chown node:node /home/node/RENAMEIT
#COPY --from=base /usr/local/bin/gosu /usr/local/bin/gosu
COPY --from=base /usr/local/bin/envconsul /usr/local/bin/envconsul
COPY --from=base /usr/local/bin/dockerize /usr/local/bin/dockerize
COPY --from=base /usr/local/bin/consul /usr/local/bin/consul
# COPY all needed resources from previous layer (dist, swagger, node_modules (Production modules only)
COPY --from=dependencies --chown=node /source-code/ /home/node/RENAMEIT/
COPY docker-entrypoint.sh /

RUN chmod u+x /docker-entrypoint.sh


ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["npm","start"]

