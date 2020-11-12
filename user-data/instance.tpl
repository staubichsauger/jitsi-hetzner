#!/bin/bash

# ---------------------- Setup requirements
ip addr add ${floating_ip} dev eth0

apt-get update
apt-get install -yqq \
 apt-transport-https \
 ca-certificates \
 curl \
 gnupg2 \
 software-properties-common \
 git \
 ufw \
 unzip

# ---------------------- Install docker
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io

curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# ---------------------- Setup Jitsi
mkdir -p /opt/dockerservices
cd /opt/dockerservices
git clone https://github.com/jitsi/docker-jitsi-meet jitsi
cd jitsi

if [ -f "/tmp/certs.zip" ]; then
	mkdir -p ~/.jitsi-meet-cfg/web/letsencrypt
	unzip /tmp/certs.zip -d ~/.jitsi-meet-cfg/web/letsencrypt
fi

mkdir -p ~/.jitsi-meet-cfg/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

cp env.example .env
sed -i "s%HTTP_PORT=.*%HTTP_PORT=80%g" .env
sed -i "s%HTTPS_PORT=.*%HTTPS_PORT=443%g" .env
sed -i "s%.*PUBLIC_URL=.*%PUBLIC_URL=${dnsname}%g" .env
sed -i "s%.*DOCKER_HOST_ADDRESS=.*%DOCKER_HOST_ADDRESS=${floating_ip}%g" .env
sed -i "s%.*ENABLE_LETSENCRYPT=.*%ENABLE_LETSENCRYPT=1%g" .env
sed -i "s%.*LETSENCRYPT_DOMAIN=.*%LETSENCRYPT_DOMAIN=${dnsname}%g" .env
sed -i "s%.*LETSENCRYPT_EMAIL=.*%LETSENCRYPT_EMAIL=${email}%g" .env
sed -i "s%.*ENABLE_LOBBY=.*%ENABLE_LOBBY=1%g" .env
sed -i "s%.*ENABLE_RECORDING=.*%ENABLE_RECORDING=0%g" .env
sed -i "s%.*ENABLE_HTTP_REDIRECT=.*%ENABLE_HTTP_REDIRECT=1%g" .env

echo ENABLE_CALENDAR=0 >> .env
echo ENABLE_FILE_RECORDING_SERVICE=0 >> .env
echo ENABLE_FILE_RECORDING_SERVICE_SHARING=0 >> .env
echo ENABLE_NO_AUDIO_DETECTION=1 >> .env
echo ENABLE_PREJOIN_PAGE=1 >> .env
echo ENABLE_TALK_WHILE_MUTED=1 >> .env

./gen-passwords.sh

#docker-compose up -d
systemctl daemon-reload
systemctl enable --now dc@jitsi.service
systemctl enable --now dc-reload@jitsi.timer

while [ $(docker-compose ps | wc -l) -lt 5 ]; do
	echo waiting
	sleep 1
done

cp /tmp/config.js ~/.jitsi-meet-cfg/web/config.js
cp /tmp/interface_config.js ~/.jitsi-meet-cfg/web/interface_config.js

if [ "x${rooms}" != "x" ]; then
	while [ ! -f ~/.jitsi-meet-cfg/web/nginx/meet.conf ]
	do
		sleep 1
	done
	echo "available rooms: ${rooms}"
	sed -i "s%location ~ ^/(.*)$ {%location ~ ^/(${rooms})$ {%g" ~/.jitsi-meet-cfg/web/nginx/meet.conf

	until docker-compose exec -T web nginx -s reload
	do
		echo retrying nginx reload
		sleep 1
	done
	echo added rooms
fi

ufw enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 4443
ufw allow 10000
ufw default deny


echo "--------------------------- finished -------------------------"
