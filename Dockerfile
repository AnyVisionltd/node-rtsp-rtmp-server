FROM node:4-onbuild

################
#  App Deps    #
################

RUN mkdir /app
WORKDIR /app
LABEL maintainer="Aharon Rubin <aharonr@anyvision.co>"

# TODO:
# Copy over your application stuff required to load up
# dependencies and then install those dependencies

ADD package.json /app/package.json
RUN npm install -d
RUN npm install -g coffee-script

## INSTALL DEPENDENCIES
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      wget \
      lsof \
      vim \
      git \
      less \
      iputils-ping \
      net-tools \
      dnsutils \
      iftop \
      htop \
      nethogs \
      traceroute \
      python3-dev \
      python3-pip \
      unzip\
      libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

## BUILD PYTHON-CONSUL
RUN pip3 install setuptools wheel python-consul

################
#  App Source  #
################

# Copy over your apps sourcecode in this section
COPY . /app/

################
#  Container Pilot #
################


# Install ContainerPilot
ENV CONTAINERPILOT_VERSION 3.4.2
RUN export CP_SHA1=5c99ae9ede01e8fcb9b027b5b3cb0cfd8c0b8b88 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/containerpilot-${CONTAINERPILOT_VERSION}.tar.gz" \
    && echo "${CP_SHA1}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /bin \
    && rm /tmp/containerpilot.tar.gz

#Install envconsul
RUN wget https://releases.hashicorp.com/envconsul/0.6.1/envconsul_0.6.1_linux_amd64.zip&&unzip envconsul_0.6.1_linux_amd64.zip\
&& ln -sf $PWD/envconsul /usr/local/bin

# COPY ContainerPilot configuration
ENV CONTAINERPILOT_PATH=/etc/containerpilot.json5
COPY devops/containerpilot.json5 ${CONTAINERPILOT_PATH}
ENV CONTAINERPILOT=${CONTAINERPILOT_PATH}


#############
#  Conclude #
#############


COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh
RUN chmod +x devops/entrypoint.sh
RUN echo ". /sbin/entrypoint.sh" > /root/.bash_history

#ENTRYPOINT ["/sbin/entrypoint.sh"]
ENTRYPOINT ["/bin/containerpilot"]
