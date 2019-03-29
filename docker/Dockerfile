FROM openjdk:8-jre

ENV \
    SOLR_VERSION=4.10.4 \
    SOLR_SHA1_CHECKSUM=0edf666bea51990524e520bdcb811e14b4de4c41 \
    SOLR_USER=solr \
    SOLR_HOME_PATH=/etc/opt/solr \
    JETTY_HOME_PATH=/etc/opt/jetty \
    SOLR_DISTRIBUTION_PATH=/opt/solr \
    SOLR_INDICES_DIR_PATH=/var/opt/solr/indices

ARG mirror_url="http://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}"

ADD build.sh /tmp/
RUN /tmp/build.sh "${mirror_url}"

ADD solr.sh /usr/local/bin/
ADD log4j.properties "${JETTY_HOME_PATH}/resources/"

USER ${SOLR_USER}
EXPOSE 8983
CMD ["solr.sh"]
