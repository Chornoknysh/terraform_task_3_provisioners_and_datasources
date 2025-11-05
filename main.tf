terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.105.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "prefix" {
  default = "tfvmex"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
locals {
  ssh_private_key = file(var.ssh_private_key_path)
  host_ip         = data.azurerm_public_ip.pip.ip_address
}

# Завантаження HTML‑файлу на VM
resource "null_resource" "upload_page" {
  triggers = {
    vm_id = data.azurerm_virtual_machine.vm.id
  }

  provisioner "file" {
    source      = "${path.module}/files/index.html"
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
      # Оновлення пакетів і встановлення Nginx
      "sudo apt-get update -y || sudo yum makecache -y",
      "command -v apt-get && sudo apt-get install -y nginx || sudo yum install -y nginx",

      # Запуск і автозапуск
      "sudo systemctl enable nginx || true",
      "sudo systemctl start nginx || sudo service nginx start || true",

      # Переміщення кастомної сторінки
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
