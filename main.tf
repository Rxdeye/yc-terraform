terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex" 
    }
  }
  required_version = ">=0.13"
}


provider "yandex" {
  token = var.yandex_token
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = "ru-central1-a"
}


resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", { 
    vm_postgres = yandex_compute_instance.vm1-postgres
})

  filename = "${path.module}/inventory.ini"
  depends_on = [
    yandex_compute_instance.vm1-postgres
  ]
}


resource "yandex_iam_service_account" "autoscale" {
  name = "autoscale"
  description = "sa for autoscale"
}


resource "yandex_vpc_security_group" "security_db" {
  name = "security-group-for-db"
  network_id = yandex_vpc_network.vm-network.id

  ingress {
    protocol = "TCP"
    port = 22
    v4_cidr_blocks = ["91.105.168.9/32"]
  }
  ingress {
    protocol = "TCP"
    port = 5432
    v4_cidr_blocks = ["192.168.1.0/24"]
  }

  egress {
    protocol = "TCP"
    port = 5432
    v4_cidr_blocks = ["192.168.1.0/24"] 
  }
  
  egress {
    protocol = "TCP"
    port = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "TCP"
    port = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "TCP"
    port = 9100
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { 
    protocol = "TCP"
    port = 9100
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "yandex_vpc_security_group" "security_bc" {
  name = "security-group-for-backend" 
  network_id = yandex_vpc_network.vm-network.id
   
  ingress {
    protocol = "TCP"
    port = 22
    v4_cidr_blocks = ["91.105.168.9/32"]
  }
  ingress {
    protocol = "TCP"
    port = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "TCP"
    port = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress { 
    protocol = "TCP"
    port = 5432
    v4_cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    protocol = "TCP"
    port = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "TCP"
    port = 9100
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "TCP"
    port = 9100
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_resourcemanager_folder_iam_member" "compute" {
  folder_id = var.folder_id
  role = "editor"
  member = "serviceAccount:${yandex_iam_service_account.autoscale.id}"
}

resource "yandex_vpc_address" "ip-db" {
  name = "db_address"
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_vpc_network" "vm-network" {
  name = "vm_network"
}


resource "yandex_lb_network_load_balancer" "my-lb" {
  depends_on = [yandex_compute_instance_group.autoscale-group]
  name = "balancer"

  listener {
    name = "my-listener"
    port = 80
    target_port = 3000
    external_address_spec {
      ip_version = "ipv4"
  }
}

  attached_target_group {
    target_group_id = yandex_compute_instance_group.autoscale-group.load_balancer[0].target_group_id
    healthcheck {
      name = "health"
      tcp_options {
        port = 3000
      }
    }
  }
}

resource "yandex_vpc_subnet" "subnet" {
  name = "vm-subnet"
  zone = "ru-central1-a"
  v4_cidr_blocks = ["192.168.1.0/24"]
  network_id = yandex_vpc_network.vm-network.id
}

resource "yandex_compute_instance_group" "autoscale-group" {
  name = "autoscale-group"
  folder_id = var.folder_id
  service_account_id = yandex_iam_service_account.autoscale.id

  instance_template {
    platform_id = "standard-v1"
    resources {
      cores = 2
      memory = 2
    } 
   
    boot_disk {
      initialize_params {
        image_id = "Packer_id"
        size = 10
      }
    }
    network_interface {
      network_id = yandex_vpc_network.vm-network.id
      subnet_ids = [yandex_vpc_subnet.subnet.id]
      security_group_ids = [yandex_vpc_security_group.security_bc.id]
      nat = true
    } 
    metadata = {
      ssh-keys = "ubuntu:${file("id_ed25519.pub")}"
    }
}

  scale_policy {
    auto_scale {
      initial_size = 2
      max_size = 4
      measurement_duration = 60
      cpu_utilization_target = 70
    }
  }
  deploy_policy {
    max_unavailable = 1
    max_expansion = 1
  }
  allocation_policy {
    zones = [
      "ru-central1-a"
    ]
  }
  load_balancer {
    target_group_name = "auto-group"
  }

}

resource "yandex_compute_instance" "vm1-postgres" {
  name = "postgresql"
  platform_id = "standard-v1"
  zone = "ru-central1-a"  

  resources {
    cores = 2
    memory = 2
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd8huqdhr65m771g1bka"
      size = 10
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    security_group_ids = [yandex_vpc_security_group.security_db.id]
    ip_address = "192.168.1.7"
    nat = true
    nat_ip_address = yandex_vpc_address.ip-db.external_ipv4_address[0].address
  }
  metadata = {
    ssh-keys = "ubuntu:${file("id_ed25519.pub")}"
  }
}

output "ip_address" {
  value = yandex_lb_network_load_balancer.my-lb.listener[*].external_address_spec[*].address
}
