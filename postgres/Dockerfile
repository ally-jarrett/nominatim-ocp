FROM crunchydata/crunchy-postgres-gis:centos7-12.5-3.0-4.4.2

ENV SUMMARY="Nominatm Postgres" \
    DESCRIPTION="Nominatim Postgres" \
    NOM_HOME=/nominatim

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Nominatim ${NOMINATIM_VERSION}" \
      io.openshift.expose-services="5432:postgres" \
      io.openshift.tags="geocoding,nominatim,database" \
      name="crunchy-postgres-gis-nominatim" \
      version=1.0 \
      maintainer="Ally Jarrett <ajarrett@redhat.com>"

USER 0

COPY /root/usr/libexec/fix-permissions /usr/libexec/fix-permissions
RUN chmod a+x /usr/libexec/fix-permissions

# Copy Nominatim.so module :: NOMINATIM_DATABASE_MODULE_PATH=/nominatim/module
RUN mkdir -p $NOM_HOME/module
COPY files/nominatim.so $NOM_HOME/module
RUN /usr/libexec/fix-permissions $NOM_HOME/module

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]