FROM balenalib/raspberry-pi-debian:buster-build as buildstep

# hadolint ignore=DL3018


RUN \
apt-get update && \
DEBIAN_FRONTEND="noninteractive" \
TZ="Europe/London" \
apt-get -y install \
erlang-nox=1:21.2.6+dfsg-1 \
erlang-dev=1:21.2.6+dfsg-1 \
git=1:2.20.1-2+deb10u3 \
libdbus-1-dev \
gcc \
g++ \
curl \
--no-install-recommends && \
apt-get autoremove -y &&\
apt-get clean && \
rm -rf /var/lib/apt/lists/*

WORKDIR /opt/cmake

RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.21.1/cmake-3.21.1.tar.gz | tar -xvzf -

WORKDIR /opt/cmake/cmake-3.21.1

RUN ./bootstrap

RUN make

RUN make install

WORKDIR /opt/gateway-config

RUN git clone https://github.com/helium/gateway-config.git


WORKDIR /opt/gateway-config/gateway-config

RUN DEBUG=1 make
RUN DEBUG=1 make release

FROM balenalib/raspberry-pi-debian:buster-run

# hadolint ignore=DL3018
RUN \
apt-get update && \
DEBIAN_FRONTEND="noninteractive" \
TZ="Europe/London" \
apt-get -y install \
erlang-nox=1:21.2.6+dfsg-1 \
python3-minimal=3.7.3-1 \
dbus \
--no-install-recommends && \
apt-get autoremove -y &&\
apt-get clean && \
rm -rf /var/lib/apt/lists/*

WORKDIR /opt/gateway-config

COPY --from=buildstep /opt/gateway-config/gateway-config/_build/prod/rel/gateway_config .
COPY --from=buildstep /opt/gateway-config/gateway-config/_build/prod/rel/gateway_config/config/com.helium.Config.conf /etc/dbus-1/system.d/

ENTRYPOINT ["sh"]
