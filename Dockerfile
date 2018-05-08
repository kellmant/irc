FROM alpine:latest
MAINTAINER kellman
USER root
COPY certs /usr/local/share/ca-certificates/
RUN apk -Uuvv add --no-cache curl openssl tini tzdata ca-certificates && \
	addgroup -g 253 fleet && \
	addgroup -g 500 core && \
	addgroup -g 600 units && \
	addgroup -g 700 boss && \
	addgroup -g 800 media && \
	addgroup -g 900 web && \
	addgroup -g 1000 git && \
	adduser -D ctrl -u 500 -g controller -G core -s /bin/bash -h /ctrl && \
	addgroup ctrl fleet && \
	addgroup ctrl units && \
	addgroup ctrl boss && \
	addgroup ctrl media && \
	addgroup ctrl web && \
	adduser -S -u 602 -G units -H irc && \
	adduser -S -u 800 -G media -H plex && \
	adduser -S -u 802 -G media -H shows && \
	adduser -S -u 803 -G media -H movies && \
	adduser -S -u 804 -G media -H music && \
	adduser -S -u 805 -G media -H sab && \
	adduser -S -u 806 -G media -H torrent && \
	adduser -S -u 901 -G web -H hexo && \
	adduser -S -u 902 -G web -H blog && \
	adduser -S -u 903 -G web -H wordpress && \
	adduser -S -u 904 -G web -H node && \
	adduser -S -u 1000 -G git -H git && \
   	mkdir -p /ctrl && chown -R ctrl.core /ctrl && \
   	mkdir -p /socket && chown -R ctrl.core /socket && \
	update-ca-certificates && \
	mkdir -p /tmp/build && cd /tmp/build && \
	curl -L https://github.com/coreos/etcd/releases/download/v3.1.8/etcd-v3.1.8-linux-amd64.tar.gz -o etcd-v3.1.8-linux-amd64.tar.gz && \
	tar xzvf etcd-v3.1.8-linux-amd64.tar.gz && cd etcd-v3.1.8-linux-amd64 && \
	cp ./etcdctl /usr/bin/ && cd /tmp/build && \
	curl -L https://github.com/coreos/fleet/releases/download/v0.11.8/fleet-v0.11.8-linux-amd64.tar.gz -o fleet.tar.gz && \
	tar xzvf fleet.tar.gz && cd fleet-v0.11.8-linux-amd64 && \
	cp ./fleetctl /usr/bin/ && \
    cd / && rm -rf /tmp/build
COPY ttyd /root/ttyd
RUN apk add --update --no-cache \
    autoconf automake bash bsd-compat-headers yarn \
    build-base ca-certificates cmake curl file g++ git libtool vim \
 && curl -sLo- https://s3.amazonaws.com/json-c_releases/releases/json-c-0.12.1.tar.gz | tar xz \
 && cd json-c-0.12.1 && env CFLAGS=-fPIC ./configure && make install && cd .. \
 && curl -sLo- https://zlib.net/zlib-1.2.11.tar.gz | tar xz \
 && cd zlib-1.2.11 && ./configure && make install && cd .. \
 && curl -sLo- https://www.openssl.org/source/openssl-1.0.2l.tar.gz | tar xz \
 && cd openssl-1.0.2l && ./config -fPIC --prefix=/usr/local --openssldir=/usr/local/openssl && make install && cd .. \
 && curl -sLo- https://github.com/warmcat/libwebsockets/archive/v2.2.1.tar.gz | tar xz \
 && cd libwebsockets-2.2.1 && cmake -DLWS_WITHOUT_TESTAPPS=ON -DLWS_STATIC_PIC=ON -DLWS_UNIX_SOCK=ON && make install && cd .. \
 && sed -i 's/libz.so/libz.a/g' /usr/local/lib/cmake/libwebsockets/LibwebsocketsTargets-release.cmake \
 && sed -i 's/ websockets_shared//' /usr/local/lib/cmake/libwebsockets/LibwebsocketsConfig.cmake \
 && rm -rf json-c-0.12.1 zlib-1.2.11 openssl-1.0.2l libwebsockets-2.2.1 \
 && cd /root/ttyd/html && yarn && yarn run build && cd .. \
 && sed -i '5s;^;\nSET(CMAKE_FIND_LIBRARY_SUFFIXES ".a")\nSET(CMAKE_EXE_LINKER_FLAGS "-static")\n;' CMakeLists.txt \
 && cmake . && make install && cd .. && rm -rf ttyd \
 && git clone https://github.com/powerline/fonts.git \
 && cd fonts && ./install.sh && cd .. && rm -rf fonts \
 && apk del --purge build-base cmake g++ autoconf automake bsd-compat-headers yarn libtool \
 && rm -rf /tmp/* \
 && rm -rf /var/cache/apk/*
RUN \
	echo -n "Gateway In The Sky Project " > /etc/motd && \
	echo -n "Securing Labs IRC Client Shell [Alpine:latest] " >> /etc/motd && \
	echo -n "overlaynetwork[TRUSTED] " >> /etc/motd && \
	apk -Uuvv add --no-cache tini tzdata build-base gcc abuild binutils cmake libffi-dev \
	openssl util-linux coreutils findutils grep fontconfig \
	jq less linux-headers perl irssi irssi-perl \ 
	bc ncurses ncurses-libs ncurses-terminfo libevent tmux xdg-utils && \
	apk del --purge build-base gcc abuild binutils cmake libffi-dev linux-headers && \
	rm -rf /root/.cache && \
	rm -rf /tmp/* && \
	rm -rf /var/cache/apk/*
COPY IRC /IRC
EXPOSE 3000
USER ctrl
ENV PATH=~/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ETCDCTL_STRICT_HOST_KEY_CHECKING=false FLEETCTL_STRICT_HOST_KEY_CHECKING=false ETCDCTL_ENDPOINTS=http://keystore:2379 TERM=xterm
WORKDIR /ctrl
ENTRYPOINT ["/sbin/tini", "-g", "--", "/usr/local/bin/ttyd", "-r", "1", "-p", "3000", "-S", "-C", "/ca/local.cert.pem", "-K", "/ca/local.key.pem"]
CMD ["/IRC"]
