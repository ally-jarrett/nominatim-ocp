FROM centos:8

USER root

ENV USERHOME=/nominatim \
    USERNAME=nominatim \
    BUILD=${USERHOME}/build \
    OSM_FLAT_FILE=/var/lib/nominatim/data \
    PBF_DIR=/var/lib/nominatim/pbf \
    PGDATA=/var/lib/pgsql/data \
    NOMINATIM_VERSION=3.7.1

ENV SUMMARY="Nominatm" \
    DESCRIPTION="Nominatim" \
    PBF_URL=http://download.geofabrik.de/europe/great-britain-latest.osm.pbf

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Nominatim ${NOMINATIM_VERSION}" \
      io.openshift.expose-services="8080:apache" \
      io.openshift.tags="geocoding,nominatim" \
      name="centos/nominatim" \
      version=${NOM_VERSION} \
      usage="docker run -p 8080:8080 nominatim" \
      maintainer="Ally Jarrett <ajarrett@redhat.com>"

# from https://github.com/sclorg/postgresql-container/blob/generated/9.6/Dockerfile
COPY postgres/root /usr/libexec/fix-permissions
RUN chmod a+x /usr/libexec/fix-permissions

# Create Nominatim User
RUN useradd -d $USERHOME -s /bin/bash -m $USERNAME \
    && /usr/libexec/fix-permissions $USERHOME

# Install the world...
RUN dnf update -y
RUN dnf install -y epel-release redhat-rpm-config dnf-plugins-core
RUN dnf -qy module disable postgresql
RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
RUN dnf --enablerepo=powertools install -y postgresql12-server postgresql12-contrib postgresql12-devel postgresql12-libs postgis30_12 \
                   wget git cmake make gcc gcc-c++ libtool policycoreutils-python-utils \
                   llvm-toolset ccache clang-tools-extra \
                   php-pgsql php php-intl php-json libpq-devel \
                   bzip2-devel proj-devel boost-devel \
                   python3-pip python3-setuptools python3-devel \
                   expat-devel zlib-devel libicu-devel \
                   glibc-locale-source glibc-langpack-en bzip2 sudo

# Required for psycopg2 install and non-systemD access
ENV PATH="/usr/pgsql-12/bin:$PATH"

RUN pip3 install psycopg2 python-dotenv psutil Jinja2 PyICU osmium
RUN dnf clean all
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

WORKDIR ${USERHOME}

# BUILD nominatim from source
RUN true \
    && mkdir $BUILD \
    && curl https://nominatim.org/release/Nominatim-$NOMINATIM_VERSION.tar.bz2 -o nominatim.tar.bz2 \
    && tar xf nominatim.tar.bz2 \
    && cd $BUILD \
    && cmake $USERHOME/Nominatim-$NOMINATIM_VERSION \
    && make \
    && make install

# Permissioning
RUN mkdir -p ${OSM_FLAT_FILE} && /usr/libexec/fix-permissions ${OSM_FLAT_FILE} \
    && mkdir -p ${PBF_DIR} && /usr/libexec/fix-permissions ${PBF_DIR} \
    && /usr/libexec/fix-permissions /var/lib/pgsql \
    && /usr/libexec/fix-permissions /usr/pgsql-12/bin \
    && mkdir -p ${PGDATA} && /usr/libexec/fix-permissions ${PGDATA} \
    && /usr/libexec/fix-permissions /var/run/postgresql \
    && /usr/libexec/fix-permissions /run/httpd \
    && usermod -a -G root postgres \
    && usermod -a -G root ${USERNAME}

# Create Mount point for OSM Files
VOLUME [ "${OSM_FLAT_FILE}", "${PGDATA}", "${PBF_DIR}" ]


## TODO  - Remove all uneeded packages post compilation
RUN rm -rf $USERHOME/nominatim.tar.bz2

# Generate Website Stuffs....
RUN nominatim refresh --website \
    && chmod -R a+rwx $PGDATA \
    && /usr/libexec/fix-permissions $USERHOME/website

# Copy over seed scripts
COPY init.sh $USERHOME/init.sh
#RUN $USERHOME/init.sh

EXPOSE 5432
#EXPOSE 8080

#USER 26

##CMD ["/usr/bin/run-nominatim"]