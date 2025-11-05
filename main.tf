locals {
  ssh_private_key = file(var.ssh_private_key_path)
  host_ip         = data.azurerm_public_ip.pip.ip_address
}

# Завантаження кастомної сторінки
resource "null_resource" "upload_page" {
  triggers = {
    vm_id = data.azurerm_virtual_machine.vm.id
  }

  provisioner "file" {
    source      = "${path.module}/index.html"   # виправлений шлях
    destination = "/tmp/index.html"

    connection {
      type        = "ssh"
      host        = local.host_ip
      user        = var.ssh_username
      private_key = local.ssh_private_key
    }
  }
}

# Встановлення Nginx і заміна дефолтної сторінки
resource "null_resource" "install_nginx" {
  triggers = {
    vm_id = data.azurerm_virtual_machine.vm.id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y || sudo yum makecache -y",
      "command -v apt-get && sudo apt-get install -y nginx || sudo yum install -y nginx",
      "sudo systemctl enable nginx || true",
      "sudo systemctl start nginx || sudo service nginx start || true",
      "sudo mv /tmp/index.html /usr/share/nginx/html/index.html",
      "sudo chmod 644 /usr/share/nginx/html/index.html"
    ]

    connection {
      type        = "ssh"
      host        = local.host_ip
      user        = var.ssh_username
      private_key = local.ssh_private_key
    }
  }

  depends_on = [null_resource.upload_page]
}
