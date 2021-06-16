#!/bin/bash -ex

if [ ! -f /etc/httpd/conf.d/nominatim.conf ]; then
    echo "nominatim.conf not found, creating /etc/httpd/conf.d/nominatim.conf"

    sudo tee /etc/httpd/conf.d/nominatim.conf << EOFAPACHECONF
    <Directory "$USERHOME/website">
      Options FollowSymLinks MultiViews
      AddType text/html   .php
      DirectoryIndex search.php
      Require all granted
    </Directory>

    Alias /nominatim $USERHOME/website
EOFAPACHECONF
fi

if [ $? -ne 0 ]
then
    echo "SELinux Disabled"
else
    echo "SELinux Enabled, setting context for Nominatim"
    sudo semanage fcontext -a -t httpd_sys_content_t "/usr/local/lib64/nominatim/lib-php(/.*)?"
    sudo semanage fcontext -a -t httpd_sys_content_t "$USERHOME/website(/.*)?"
    sudo semanage fcontext -a -t lib_t "$USERHOME/module/nominatim.so"
    sudo restorecon -R -v /usr/local/lib64/nominatim
    sudo restorecon -R -v $USERHOME/website
fi

HTTPD_MAIN_CONF_PATH=/etc/httpd/conf \
HTTPD_MAIN_CONF_D_PATH=/etc/httpd/conf.d \
HTTPD_VAR_RUN=/var/run/httpd \
HTTPD_DATA_PATH=/var/www \
HTTPD_LOG_PATH=/var/log/httpd \

/usr/libexec/fix-permissions $HTTPD_VAR_RUN
/usr/libexec/fix-permissions $HTTPD_DATA_PATH
/usr/libexec/fix-permissions $HTTPD_LOG_PATH

sed -i -e 's/^Listen 80/Listen 0.0.0.0:8080/' /etc/httpd/conf/httpd.conf
sed -i -e '151s%AllowOverride None%AllowOverride All%' /etc/httpd/conf/httpd.conf