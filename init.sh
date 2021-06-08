#!/bin/bash -ex

OSMFILE=${USERHOME}/data.osm.pbf

if [ "$IMPORT_WIKIPEDIA" = "true" ]; then
  echo "Downloading Wikipedia importance dump"
  curl https://www.nominatim.org/data/wikimedia-importance.sql.gz -o ${USERHOME}/wikimedia-importance.sql.gz
else
  echo "Skipping optional Wikipedia importance import"
fi;

if [ "$IMPORT_GB_POSTCODES" = "true" ]; then
  curl https://www.nominatim.org/data/gb_postcode_data.sql.gz -o ${USERHOME}/gb_postcode_data.sql.gz
else \
  echo "Skipping optional GB postcode import"
fi;

if [ "$IMPORT_US_POSTCODES" = "true" ]; then
  curl https://www.nominatim.org/data/us_postcode_data.sql.gz -o ${USERHOME}/us_postcode_data.sql.gz
else
  echo "Skipping optional US postcode import"
fi;

if [ ! -f ${OSMFILE} ]; then
  echo Downloading OSM extract from "$PBF_URL"
  sudo -E -u nominatim curl -L "$PBF_URL" --create-dirs -o $OSMFILE
fi

# if we use a bind mount then the PG directory is empty and we have to create it
if [ ! -f ${PGDATA}/PG_VERSION ]; then
  chown postgres ${PGDATA}
  sudo -E -u postgres initdb -E UTF8 -D ${PGDATA}
fi

if [[ `ps -acx|grep postgres|wc -l` -lt 1 ]]; then
  echo "Postgres server not running, starting..."
  sudo -E -u postgres pg_ctl -w -D $PGDATA -l logfile start
fi

sudo -E -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='nominatim'" | grep -q 1 || createuser -s nominatim && \
sudo -E -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='www-data'" | grep -q 1 || createuser -SDR www-data && \

#sudo -u postgres psql postgres -tAc "ALTER USER nominatim WITH ENCRYPTED PASSWORD '$NOMINATIM_PASSWORD'" && \
#sudo -u postgres psql postgres -tAc "ALTER USER \"www-data\" WITH ENCRYPTED PASSWORD '${NOMINATIM_PASSWORD}'" && \

sudo -E -u postgres psql postgres -c "DROP DATABASE IF EXISTS nominatim"

#chown -R nominatim:nominatim ${USERHOME}

cd ${USERHOME}
sudo -E -u nominatim nominatim import --osm-file $OSMFILE --threads $THREADS
sudo -E -u nominatim nominatim admin --check-database
sudo -E -u nominatim nominatim replication --init

#sudo service postgresql stop

# Remove slightly unsafe postgres config overrides that made the import faster
#rm /etc/postgresql/12/main/conf.d/postgres-import.conf

#echo "Deleting downloaded dumps in ${USERHOME}"
#rm -f ${USERHOME}/*sql.gz ${OSMFILE}
