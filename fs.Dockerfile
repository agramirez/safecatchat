FROM debian:trixie
LABEL Author: Alex Ramirez <alexandergramirez@gmail.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git nano

RUN git clone https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp


# build (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    build-essential cmake automake autoconf 'libtool-bin|libtool' pkg-config
# general (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses5-dev libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff5-dev uuid-dev
# core (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libpcre2-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm
# core codecs (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libogg-dev libspeex-dev libspeexdsp-dev 
# mod_enum (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libldns-dev 
# mod_python3 (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    python3-dev 
# mod_av (err, libavresample-dev, switched to libswresample-dev)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libavformat-dev libswscale-dev libswresample-dev 
# mod_lua (ok, although 5.2 contains vulnerabilities and latest is 5.4, but with API differences)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    liblua5.2-dev 
# mod_opus (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libopus-dev
# mod_pgsql (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libpq-dev
# mod_sndfile (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev 
# mod_shout (ok)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    libshout3-dev libmpg123-dev libmp3lame-dev

# ok
RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
# ok
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install
# ok
RUN cd /usr/src/libs/spandsp && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
# got rid of signalwire
#RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

# Enable modules
RUN sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' /usr/src/freeswitch/build/modules.conf.in

RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN cd /usr/src/freeswitch && ./configure
RUN cd /usr/src/freeswitch && make -j`nproc` && make install

ENV PATH="$PATH:/usr/local/freeswitch/bin"

# change default password...acheles heal of freeswitch
RUN FS_PASS=$(base64 </dev/urandom | head -c 16) && sed "s|default_password=1234|default_password=$FS_PASS|" /usr/local/freeswitch/conf/vars.xml

# Cleanup the image
RUN apt-get clean

# Uncomment to cleanup even more
RUN rm -rf /usr/src/*

CMD ["sleep","infinity"]