#!/bin/bash

if [ -f tmp/certs.zip ]; then
	echo "using already exisiting certificates"
else
	echo "no exisiting certificates found, using dummy file"
	touch dummy
	mkdir -p tmp
	zip tmp/certs.zip dummy
	rm dummy
fi

terraform plan
terraform apply 

ssh -o StrictHostKeyChecking=no -i $(cat variables.tf | grep id_rsa\" | sed 's#.*"\(.*id_rsa.*\).*"#\1#g') root@"$(cat terraform.tfvars | grep dnsname | sed 's#dnsname = "\(.*\)"#\1#g')" tail -f /var/log/cloud-init-output.log
