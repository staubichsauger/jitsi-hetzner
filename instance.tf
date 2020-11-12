resource "hcloud_server" "server" {
  name = "server-${local.name}"
  image = var.image
  server_type = var.server_type
  location = var.location
  backups = "false"
  ssh_keys = [hcloud_ssh_key.user.id]
  user_data = data.template_file.instance.rendered

  connection {
    type = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host = self.ipv4_address
  }

  provisioner "file" {
    source = "tmp/certs.zip"
    destination = "/tmp/certs.zip"
  }
  provisioner "file" {
    source = "user-data/config.js"
    destination = "/tmp/config.js"
  }
  provisioner "file" {
    source = "user-data/interface_config.js"
    destination = "/tmp/interface_config.js"
  }
  provisioner "file" {
    source = "user-data/dc-reload@.service"
    destination = "/etc/systemd/system/dc-reload@.service"
  }
  provisioner "file" {
    source = "user-data/dc-reload@.timer"
    destination = "/etc/systemd/system/dc-reload@.timer"
  }
  provisioner "file" {
    source = "user-data/dc@.service"
    destination = "/etc/systemd/system/dc@.service"
  }
}

# File definition user-data
data "template_file" "instance" {
    template = file("${path.module}/user-data/instance.tpl")
    vars = {
        floating_ip = data.hcloud_floating_ip.video.ip_address
        dnsname = var.dnsname
        email = var.email
	rooms = var.rooms
    }
}

# Definition ssh key from variable
resource "hcloud_ssh_key" "user" {
    name = "user"
    public_key = file(var.public_key_path)
}

data "hcloud_floating_ip" "video" {
  name = var.floating_ip_name
}

resource "hcloud_floating_ip_assignment" "video" {
  floating_ip_id = data.hcloud_floating_ip.video.id
  server_id = hcloud_server.server.id
}
