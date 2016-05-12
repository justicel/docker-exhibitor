FROM debian:7.8
MAINTAINER Secret Sauce Partners, Inc. <operations@sspinc.io>

ENV \
    ZK_RELEASE="http://www.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz" \
    EXHIBITOR_POM="https://raw.githubusercontent.com/Netflix/exhibitor/44905c150e648c640f8ef961f388d3972af05947/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml" \
    # Append "+" to ensure the package doesn't get purged
    BUILD_DEPS="curl maven openjdk-7-jdk+" \
    DEBIAN_FRONTEND="noninteractive"

# Use one step so we can remove intermediate dependencies and minimize size
RUN \
    # Install dependencies
    apt-get update \
    && apt-get install -y --allow-unauthenticated --no-install-recommends $BUILD_DEPS \

    # Default DNS cache TTL is -1. DNS records, like, change, man.
    && grep '^networkaddress.cache.ttl=' /etc/java-7-openjdk/security/java.security || echo 'networkaddress.cache.ttl=60' >> /etc/java-7-openjdk/security/java.security \

    # Install ZK
    && curl -Lo /tmp/zookeeper.tgz $ZK_RELEASE \
    && mkdir -p /opt/zookeeper/transactions /opt/zookeeper/snapshots \
    && tar -xzf /tmp/zookeeper.tgz -C /opt/zookeeper --strip=1 \
    && rm /tmp/zookeeper.tgz \

    # Install Exhibitor
    && mkdir -p /opt/exhibitor \
    && curl -Lo /opt/exhibitor/pom.xml $EXHIBITOR_POM \
    && mvn -f /opt/exhibitor/pom.xml package \
    && ln -s /opt/exhibitor/target/exhibitor*jar /opt/exhibitor/exhibitor.jar \

    # Remove build-time dependencies
    && apt-get purge -y --auto-remove $BUILD_DEPS \
    && rm -rf /var/lib/apt/lists/*

# Add the optional web.xml for authentication
ADD web.xml /opt/exhibitor/web.xml

# Add entrypoint script
ADD docker-entrypoint.sh /entrypoint.sh

WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["/entrypoint.sh"]