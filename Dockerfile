FROM ubuntu:16.04

ARG S6_OVERLAY_VERSION=v1.17.2.0
ARG DEBIAN_FRONTEND="noninteractive"
ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

ENTRYPOINT ["/init"]

RUN apt-get update && \
    apt-get install -y \
      tzdata \
      curl \
      xmlstarlet \
      uuid-runtime \
      python3-pip

# Fetch and extract S6 overlay
RUN curl -J -L -o /tmp/s6-overlay-amd64.tar.gz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# Add user
RUN useradd -U -d /config -s /bin/false plex
RUN usermod -G users plex

# Setup directories
RUN mkdir -p \
      /config \
      /transcode \
      /data

# Cleanup
RUN apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp

VOLUME /config /transcode

ENV CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

ARG TAG=plexpass
ARG URL=

COPY root/ /

RUN chown -R plex:plex /config /transcode /data

RUN /installBinary.sh

RUN pip install plexurl

HEALTHCHECK --interval=200s --timeout=100s CMD /healthcheck.sh || exit 1

