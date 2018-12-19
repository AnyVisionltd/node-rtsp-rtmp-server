FROM node:10-alpine

RUN mkdir /app
WORKDIR /app
LABEL maintainer="Aharon Rubin <aharonr@anyvision.co>"

# TODO:
# Copy over your application stuff required to load up
# dependencies and then install those dependencies

RUN apk update \
 && apk add curl

ADD package.json /app/package.json
RUN npm install -d
RUN npm install -g coffee-script

# Copy over your apps sourcecode in this section
COPY . /app/

# Install ContainerPilot
ENV CONTAINERPILOT_VERSION 3.4.2
RUN export CP_SHA1=5c99ae9ede01e8fcb9b027b5b3cb0cfd8c0b8b88 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/containerpilot-${CONTAINERPILOT_VERSION}.tar.gz" \
    && echo "${CP_SHA1}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /bin \
    && rm /tmp/containerpilot.tar.gz

# COPY ContainerPilot configuration
ENV CONTAINERPILOT_PATH=/etc/containerpilot.json5
COPY devops/containerpilot.json5 ${CONTAINERPILOT_PATH}
ENV CONTAINERPILOT=${CONTAINERPILOT_PATH}

ENTRYPOINT ["/bin/containerpilot"]
