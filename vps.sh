#!/bin/bash

# Initialization var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

# Go to root
cd

# Disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# Install wget and curl
apt-get update;apt-get -y install wget curl;

# Set Location GMT +7
ln -fs /usr/share/zoneinfo/Asia/Thailand /etc/localtime

# Set Locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# Set repo
cat > /etc/apt/sources.list <<END2
deb http://cdn.debian.net/debian wheezy main contrib non-free
deb http://security.debian.org/ wheezy/updates main contrib non-free
deb http://packages.dotdeb.org wheezy all
deb http://download.webmin.com/download/repository sarge contrib
deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib
END2
wget "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/dotdeb.gpg"
wget "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/jcameron-key.asc"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg
cat jcameron-key.asc | apt-key add -;rm jcameron-key.asc

# Update
apt-get update

# Install Webserver
apt-get -y install nginx

# Install Essential Package
apt-get -y install nano iptables dnsutils openvpn screen whois ngrep unzip unrar

# Install Screenfetch
cd
wget -O /usr/bin/screenfetch "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/screenfetch"
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# Install Webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
cat > /etc/nginx/nginx.conf <<END3
user www-data;
worker_processes 1;
pid /var/run/nginx.pid;
events {
	multi_accept on;
  worker_connections 1024;
}
http {
	gzip on;
	gzip_vary on;
	gzip_comp_level 5;
	gzip_types    text/plain application/x-javascript text/xml text/css;
	autoindex on;
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  server_tokens off;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;
  client_max_body_size 32M;
	client_header_buffer_size 8m;
	large_client_header_buffers 8 8m;
	fastcgi_buffer_size 8m;
	fastcgi_buffers 8 8m;
	fastcgi_read_timeout 600;
  include /etc/nginx/conf.d/*.conf;
}
END3
mkdir -p /home/vps/public_html
wget -O /home/vps/public_html/index.html "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/index.html"
echo "<?phpinfo(); ?>" > /home/vps/public_html/info.php
args='$args'
uri='$uri'
document_root='$document_root'
fastcgi_script_name='$fastcgi_script_name'
cat > /etc/nginx/conf.d/vps.conf <<END4
server {
  listen       85;
  server_name  127.0.0.1 localhost;
  access_log /var/log/nginx/vps-access.log;
  error_log /var/log/nginx/vps-error.log error;
  root   /home/vps/public_html;
  location / {
    index  index.html index.htm index.php;
    try_files $uri $uri/ /index.php?$args;
  }
  location ~ \.php$ {
    include /etc/nginx/fastcgi_params;
    fastcgi_pass  127.0.0.1:9000;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  }
}
END4
service nginx restart

# Install OpenVPN
wget -O /etc/openvpn/openvpn.tar "https://github.com/nwqionmwklqfnkno/Extra/raw/master/Script/openvpn.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/1194.conf"
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables_new.conf
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/iptables.conf"
chmod +x /etc/network/if-up.d/iptables
service openvpn restart

# Create Config OpenVPN
cd /etc/openvpn/
wget -O /etc/openvpn/client.ovpn "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/client.conf"
sed -i $MYIP2 /etc/openvpn/client.ovpn;
cp client.ovpn /home/vps/public_html/

# Install Vnstat
cd
apt-get -y install vnstat
vnstat -u -i eth0

# Install Badvpn
wget -O /usr/bin/badvpn-udpgw "https://github.com/nwqionmwklqfnkno/Extra/raw/master/Script/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://github.com/nwqionmwklqfnkno/Extra/raw/master/Script/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# Setting Port SSH
cd
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
service ssh restart

# Install Dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 443 -p 80"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart

# Install Squid3
cd
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/squid3.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;

# Install Script
cd /usr/local/bin
wget https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/menu
wget https://raw.githubusercontent.com/nwqionmwklqfnkno/Extra/master/Script/speedtest
chmod +x menu
chmod +x speedtest

# Finishing
cd
chown -R www-data:www-data /home/vps/public_html
service nginx start
service openvpn restart
service cron restart
service ssh restart
service dropbear restart
service vnstat restart
service squid3 restart
rm -rf ~/.bash_history && history -c

# info
clear
echo "=====================================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo " - OpenVPN  : TCP Port 1194"  | tee -a log-install.txt
echo " - OpenSSH  : Port 22, 143"  | tee -a log-install.txt
echo " - Dropbear : port 80, 443"  | tee -a log-install.txt
echo " - Squid3   : port 8080, 3128"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Download Config OpenVPN  : http://$MYIP:85/client.ovpn"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "====================================================="  | tee -a log-install.txt
echo "หลังจากติดตั้งสำเร็จ... กรุณาพิมพ์คำสั่ง menu เพื่อไปยังขั้นตอนถัดไป"  | tee -a log-install.txt
echo "====================================================="  | tee -a log-install.txt
cd
rm -f /root/Install.sh
