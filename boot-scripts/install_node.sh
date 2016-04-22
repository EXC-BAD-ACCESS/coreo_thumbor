#!/bin/bash

coreo_dir="$(pwd)"
files_dir="$(pwd)/../files"

yum -y update

#install thumbor
yum -y install python-devel gcc autoconf.noarch automake git
yum -y install libjpeg-turbo-devel.x86_64 libjpeg-turbo-utils.x86_64 libtiff-devel.x86_64 libpng-devel.x86_64 pngcrush jasper-devel.x86_64 libwebp-devel.x86_64 python-pip 
pip install pycurl  
pip install numpy

git clone https://github.com/kohler/gifsicle.git  
cd gifsicle  
./bootstrap.sh
./configure
make  
make install  
cd ../  
rm -rf gifsicle/

pip install thumbor
#pip install https://github.com/99designs/thumbor_botornado/archive/v2.0.1.tar.gz
pip install tc_aws
pip install boto3

cp "$files_dir/pngcrush.py" "/usr/local/lib64/python2.7/site-packages/thumbor/optimizers/pngcrush.py " 
cp "$files_dir/gifsicle.py" "/usr/local/lib64/python2.7/site-packages/thumbor/optimizers/gifsicle.py " 


THUMBOR=/etc/thumbor.conf
/usr/local/bin/thumbor-config > $THUMBOR.old
cat $THUMBOR.old "$files_dir/thumbor.conf" > $THUMBOR
rm $THUMBOR.old

sed -i -e "s/#LOADER\(.*\)=\(.*\)'thumbor.loaders.http_loader'/LOADER\1=\2'tc_aws.loaders.s3_loader'/" $THUMBOR
sed -i -e "s/#SECURITY_KEY\(.*\)=\(.*\)'MY_SECURE_KEY'/SECURITY_KEY\1=\2'mTf3FVAo5F8ST3uEf6X1f7waUgP0ukYV'/" $THUMBOR
#sed -i -e "s/#RESPECT_ORIENTATION\(.*\)=\(.*\)False/RESPECT_ORIENTATION\1=\2True/" $THUMBOR

#ALLOW_UNSAFE_URL = True
#ALLOW_OLD_URLS = True

#install supervisor
easy_install supervisor

SUPERVISORD=/etc/init.d/supervisord
chmod +x "$files_dir/supervisord"
cp "$files_dir/supervisord" $SUPERVISORD
chkconfig --add supervisord

cp "$files_dir/supervisord.conf" /etc/supervisord.conf
sed -i -e "s/THUMBOR_ACCESS_KEY_ID/$THUMBOR_ACCESS_KEY_ID/" /etc/supervisord.conf
sed -i -e "s/THUMBOR_SECRET_ACCESS_KEY/$THUMBOR_SECRET_ACCESS_KEY/" /etc/supervisord.conf
$SUPERVISORD start

#install nginx
yum -y install nginx --enablerepo=epel
NGINX="/etc/nginx"

mkdir -p $NGINX/sites-available
mkdir -p $NGINX/sites-enabled
cp "$files_dir/nginx.conf" "$NGINX/nginx.conf"
cp "$files_dir/thumbor.nginx.conf" "$NGINX/sites-available/thumbor.$DNS_ZONE.conf"
ln -s "$NGINX/sites-available/thumbor.$DNS_ZONE.conf" "$NGINX/sites-enabled/thumbor.$DNS_ZONE.conf"

service nginx restart
/sbin/chkconfig nginx on

