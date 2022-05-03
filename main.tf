// Provider configuration
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.access["token"]
  cloud_id  = var.access["cloud_id"]
  folder_id = var.access["folder_id"]
  zone      = var.access["zone"]
}
// Provider configuration

// Create VM
resource "yandex_compute_instance" "msk-ngx-servers" {

  name                      = "msk-ngx-${count.index+1}"
  count                     = var.data["count"]
  platform_id               = "standard-v1"
  hostname                  = "msk-ngx-${count.index+1}"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd82re2tpfl4chaupeuf" //Ubuntu 20.04 LTS (ubuntu-20-04-lts-v20220502)
      size     = 10
      type     = "network-ssd"
    }
  }
  
  secondary_disk {
    disk_id = yandex_compute_disk.msk-ngx-secondary-data-disk[count.index].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.web-servers-subnet-01.id
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}
// Create VM

// Create Networks
resource "yandex_vpc_network" "web-servers-network-01" {
  name = "web-servers-network-01"
}
// Create Networks

// Create Subnets
resource "yandex_vpc_subnet" "web-servers-subnet-01" {
  name           = "web-servers-subnet-01"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.web-servers-network-01.id
  v4_cidr_blocks = ["10.158.0.0/24"]
}
// Create Subnets

// Create secondary disks

resource "yandex_compute_disk" "msk-ngx-secondary-data-disk" {

  count = var.data["count"]
  name = "msk-ngx-secondary-data-disk-${count.index+1}"
  type = "network-hdd"
  zone = "ru-central1-a"
  size = "5"
}
// Create secondary disks

// Outputs

output "external_ip_address_msk-ngx-servers" {
  value = [yandex_compute_instance.msk-ngx-servers[*].hostname,yandex_compute_instance.msk-ngx-servers[*].network_interface.0.nat_ip_address]
}

output "internal_ip_address_msk-ngx-servers" {
  value = [yandex_compute_instance.msk-ngx-servers[*].hostname,yandex_compute_instance.msk-ngx-servers[*].network_interface.0.ip_address]
}
// Outputs

// Ansible Provision

resource "null_resource" "ansible-install" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = format("ansible-playbook -D -i %s, -u ${var.data["account"]} ${path.module}/provision.yml",
    join("\",\"", yandex_compute_instance.msk-ngx-servers[*].network_interface.0.nat_ip_address)
    )
  }
}
// Ansible Provision