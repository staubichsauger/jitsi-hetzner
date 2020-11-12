# Deploy a Jitsi Meet instance to the Hetzner Cloud using terraform

This repository contains a [terraform](https://www.terraform.io/) configuration to deploy [Jitsi Meet](https://meet.jit.si/) to the [Hetzner Cloud](https://www.hetzner.com/cloud) using [docker-jitsi-meet](https://github.com/jitsi/docker-jitsi-meet).

## Prerequisites

- Terraform installation
- Hetzner Cloud account and API token for the project you want to deploy to
- Floating IPv4 address inside the Hetzner Cloud project
- Domain name with the DNS A-record pointing to the Hetzner Cloud floating IP address
- ssh-keygen installed or ssh key without password protection

## Setup

Rename ```terraform.tfvars.example``` to ```terraform.tfvars``` and add your desired configuration to it:
- hcloud_token is your Hetzner Cloud API token
- dnsname is the domain name which point to the floating IP
- email will be used as email for the letsencrypt certificates
- rooms: if you only want to allow certain rooms from being opened, add a list of their names here, in the following format: "room1|room2|room3".

Set your desired values inside the ```variables.tf``` file (do NOT place the info contained in the ```terraform.tfvars``` inside this file as well!):
- image: I only tested debian, you may try a different image without any guarantees
- server_type: size of the server - I don't have much experience yet, but 2c/4g (cx21) and 3c/4g (cpx21) have worked with a few people so far.
- loaction: location of the server, choose the one closest to you. keep in mind the floating IP must be located at the same location!
-floating_ip_name: name you have given the floating IP
- public/private_key_path: path to a public/private ssh key used to access the VM. this only seems to accept ssh keys without a password. You can execute the ```gen-tmp-key.sh``` which will create a new password-less ssh keypair inside a new ```tmp``` folder. Use ssh -i ```tmp/id_rsa root@<your-domain-name>``` to ssh into the VM.

Have a look at the ```user-data/*.js``` files to see if the settings are as desired.

## Deployment
Run ```terraform init``` when deploying for the first time. Afterwards run the ```start.sh``` script. Check the changes before typing ```yes``` at the apply step.

Wait until the init script has finished. Use <CTRL + C> to get back to the terminal.

Once you don't need the server any more, run the ```stop.sh``` script. This will copy the letsencrypt certificate to the ```tmp``` folder, inside a ```certs.zip``` file. This will be provisioned to the server the next time you run the ```start.sh``` script to reuse the certificate and avoid hitting letsencrypt's rate limit.

## Acknowledgments
The following links were essential to the creation this project:
- [Terraform + Hetzner](https://blog.maddevs.io/terraform-hetzner-1df05267baf0)
- [Docker compose as a systemd unit](https://gist.github.com/mosquito/b23e1c1e5723a7fd9e6568e5cf91180f)

## Licences
This project contains two configuration files (```user-data/config.js``` and ```user-data/interface_config.js```) which were copied and modified from jitsi-meet, which is distributed under the Apache License 2.0. A copy of this licence is provided here: ```user-data/JITSI-LICENCE```.
