# https://www.geowebcache.org/
ARG MAVEN_IMAGE_TAG=3.8-eclipse-temurin-11
ARG TOMCAT_IMAGE_TAG=9-jre11-temurin-jammy
ARG GEOWEBCACHE_GIT_URL=https://github.com/GeoWebCache/geowebcache.git
ARG GEOWEBCACHE_VERSION=1.23.1

# Builder
FROM docker.io/library/maven:${MAVEN_IMAGE_TAG} AS BUILDER

ARG GEOWEBCACHE_VERSION
ARG GEOWEBCACHE_GIT_URL
ARG MAVEN_OPTS="-Xmx512M"

ENV MAVEN_OPTS ${MAVEN_OPTS}

WORKDIR /root

RUN git clone ${GEOWEBCACHE_GIT_URL} geowebcache

WORKDIR /root/geowebcache

RUN set -xe && \
    git checkout tags/${GEOWEBCACHE_VERSION} -b docker-builder && \
    # Rename directory, to make it equal geoserver and geonetwork
    mv geowebcache/ src/

VOLUME ["/root/.m2"]

WORKDIR /root/geowebcache/src

RUN mvn -DskipTests clean install | tee install.log && \
    mv install.log ./web/target/geowebcache/install.log

# Release
FROM docker.io/library/tomcat:${TOMCAT_IMAGE_TAG} AS RELEASE

ARG GEOWEBCACHE_VERSION
ARG GEOWEBCACHE_GIT_URL

LABEL org.opencontainers.image.title "GeoWebCache SGB/CPRM"
LABEL org.opencontainers.image.description "Build de GeoWebCache como imagem de container"
LABEL org.opencontainers.image.vendor "SGB/CPRM"
LABEL org.opencontainers.image.version ${GEOWEBCACHE_VERSION}
LABEL org.opencontainers.image.source ${GEOWEBCACHE_GIT_URL}
LABEL org.opencontainers.image.authors "Carlos Eduardo Mota <carlos.mota@sgb.gov.br>"

# Copy built
COPY --from=BUILDER /root/geowebcache/src/web/target/geowebcache/ ${CATALINA_HOME}/webapps/geowebcache/

EXPOSE 8080

CMD ["catalina.sh", "run"]
