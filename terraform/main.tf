# Data: Используем существующую VPC (default)

data "yandex_vpc_network" "default_vpc" {
  name = "default"
}

### Подсети

# Публичная подсеть (для Bastion и ALB)
resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet"
  zone           = var.zone_public      # например, "ru-central1-d"
  network_id     = data.yandex_vpc_network.default_vpc.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

# Приватные подсети для Web-серверов
resource "yandex_vpc_subnet" "private_subnet_1" {
  name           = "private-subnet-1"
  zone           = var.zone_private1
  network_id     = data.yandex_vpc_network.default_vpc.id
  v4_cidr_blocks = ["10.10.2.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
}

resource "yandex_vpc_subnet" "private_subnet_2" {
  name           = "private-subnet-2"
  zone           = var.zone_private2
  network_id     = data.yandex_vpc_network.default_vpc.id
  v4_cidr_blocks = ["10.10.3.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
}

### Security Groups


# Security Group для Bastion
resource "yandex_vpc_security_group" "bastion_sg" {
  name       = "bastion-sg"
  network_id = data.yandex_vpc_network.default_vpc.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Web-серверов
resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg"
  network_id = data.yandex_vpc_network.default_vpc.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.10.1.0/24"]  # только Bastion
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]      # HTTP
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]      # HTTPS
  }

  # правило ICMP
  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.10.1.0/24"]  # разрешить ping только с бастиона
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Zabbix
resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "zabbix-sg"
  network_id = data.yandex_vpc_network.default_vpc.id

  # Разрешаем SSH-доступ (только для управления)
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Разрешаем веб-интерфейс Zabbix (порт 80)
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Разрешаем доступ для агентов Zabbix (10050, 10051)
  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Groups для Elasticsearch
resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name = "elasticsearch-sg"
  network_id = data.yandex_vpc_network.default_vpc.id 
 
  ingress {
    protocol       = "TCP"
    description    = "Allow internal access to Elasticsearch"
    port          = 9200
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Groups для Kibana
resource "yandex_vpc_security_group" "kibana_sg" {
  name = "kibana-sg"
  network_id = data.yandex_vpc_network.default_vpc.id  

  ingress {
    protocol       = "TCP"
    description    = "Allow internal access to Kibana"
    port          = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


### NAT-шлюз и маршрут

data "yandex_vpc_gateway" "existing_nat_gateway" {
  name = "nat-gateway"
}

resource "yandex_vpc_route_table" "nat_route" {
  name       = "nat-route"
  network_id = data.yandex_vpc_network.default_vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = data.yandex_vpc_gateway.existing_nat_gateway.id
  }
}

### Виртуальные машины

# Bastion Host (в публичной подсети)
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  zone        = var.zone_public
  # hostname    = "bastion.ru-central1.internal"
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Web-сервер 1 (в приватной подсети 1)
resource "yandex_compute_instance" "web1" {
  name        = "web-server-1"
  zone        = var.zone_private1
 # hostname    = "web1.ru-central1.internal"
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_1.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Web-сервер 2 (в приватной подсети 2)
resource "yandex_compute_instance" "web2" {
  name        = "web-server-2"
  zone        = var.zone_private2
  # hostname    = "web2.ru-central1.internal"
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_2.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

#Zabbix Server
resource "yandex_compute_instance" "zabbix_server" {
  name        = "zabbix-server"
  zone        = var.zone_public
  # hostname    = "zabbix.ru-central1.internal"
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.zabbix_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

#Elasticsearch
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname = "elasticsearch"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet_1.id
    nat       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

#Kibana
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"
  allow_stopping_for_update = true
  
resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}


### Load Balancer и связанные ресурсы


# 1. Target Group с Web-серверами
resource "yandex_alb_target_group" "web_tg" {
  name = "web-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_1.id
    ip_address = yandex_compute_instance.web1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_2.id
    ip_address = yandex_compute_instance.web2.network_interface.0.ip_address
  }
}

# 2. Backend Group с Health Check
resource "yandex_alb_backend_group" "web_bg" {
  name = "web-backend-group"

  http_backend {
    name              = "web-backend"
    weight            = 1
    port              = 80
    target_group_ids  = [yandex_alb_target_group.web_tg.id]

    healthcheck {
      timeout  = "2s"
      interval = "5s"
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# 3. HTTP Router
resource "yandex_alb_http_router" "web_router" {
  name = "web-http-router-2"
}

# 4. Виртуальный хост для роутинга
resource "yandex_alb_virtual_host" "web_vhost" {
  name           = "web-vhost"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "web-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
      }
    }
  }
}

# 5. Application Load Balancer
resource "yandex_alb_load_balancer" "web_alb" {
  name       = "web-load-balancer"
  network_id = data.yandex_vpc_network.default_vpc.id

  allocation_policy {
    location {
      zone_id   = var.zone_public
      subnet_id = yandex_vpc_subnet.public_subnet.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {} 
      }
      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
}
