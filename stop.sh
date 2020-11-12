#!/bin/bash

scp -r -i $(cat variables.tf | grep id_rsa\" | sed 's#.*"\(.*id_rsa.*\).*"#\1#g') root@"$(cat terraform.tfvars | grep dnsname | sed 's#dnsname = "\(.*\)"#\1#g')":~/.jitsi-meet-cfg/web/letsencrypt tmp/backup

REPO_PATH=$(pwd)

cd tmp/backup
zip -r certs.zip .
mv certs.zip $REPO_PATH/tmp/
cd $REPO_PATH

rm -rf tmp/backup

terraform destroy
