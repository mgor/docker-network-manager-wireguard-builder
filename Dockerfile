ARG RELEASE
FROM mgor/docker-ubuntu-pkg-builder:$RELEASE

LABEL org.opencontainers.image.authors="Mikael Göransson <github@mgor.se>"

ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_DIRECTORY /usr/local/src
ENV BUILD_SCRIPT /usr/local/bin/build.sh
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Using apt-get due to warning with apt:
# WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
RUN apt-get update && \
    apt-get install -y apt-utils locales && \
    locale-gen en_US.UTF-8 && \
    apt-get install -y \
        wireguard \
        dh-autoreconf \
        libglib2.0-dev \
        intltool \
        libgtk-3-dev \
        libnma-dev \
        libsecret-1-dev \
        network-manager-dev \
        sudo \
	&& \
    # Clean up!
    rm -rf /var/lib/apt/lists/*

COPY build.sh ${BUILD_SCRIPT}

RUN chmod 755 ${BUILD_SCRIPT}

WORKDIR ${BUILD_DIRECTORY}

CMD ${BUILD_SCRIPT}
