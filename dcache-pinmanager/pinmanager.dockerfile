FROM ubuntu:18.04

LABEL Name="dCache PinManager"
LABEL Version="v1"
WORKDIR /dcache

ENV DEBIAN_FRONTEND=noninteractive
ENV DCACHE_DB_PASSWORD=dcachepass
ENV pgver=13

RUN apt-get update && \
    apt-get install -y wget tar apt-utils locales openssh-client rsyslog apache2-utils iputils-ping telnet

# OpenJDK 21 (same as others)
RUN wget https://download.java.net/openjdk/jdk21/ri/openjdk-21+35_linux-x64_bin.tar.gz -O /tmp/openjdk.tar.gz && \
    mkdir -p /opt/java/openjdk-21 && \
    tar -xzf /tmp/openjdk.tar.gz -C /opt/java/openjdk-21 --strip-components=1 && \
    rm /tmp/openjdk.tar.gz

ENV JAVA_HOME=/opt/java/openjdk-21
ENV PATH=$JAVA_HOME/bin:$PATH
ENV JAVA_OPTS="-Djava.net.preferIPv4Stack=true"

# Install dCache
RUN wget https://www.dcache.org/old/downloads/1.9/repo/10.2/dcache_10.2.10-1_all.deb
RUN dpkg -i dcache_10.2.10-1_all.deb || (apt-get update && apt-get install -f -y)
RUN rm dcache_10.2.10-1_all.deb

# Copy configs (adapt paths as needed)
COPY config/dcache.conf /etc/dcache/dcache.conf
COPY config/mylayout.conf /etc/dcache/layouts/mylayout.conf
COPY config/gplazma.conf /etc/dcache/gplazma.conf
COPY config/multi-mapfile /etc/dcache/multi-mapfile
COPY config/ban.conf /etc/dcache/ban.conf
RUN mkdir -p /etc/grid-security && mkdir -p /etc/grid-security/certificates
COPY config/storage-authzdb /etc/grid-security/storage-authzdb

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]