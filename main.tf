data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "bastion" {

  name = "bastion"
  zone = "ru-central1-a" 
  platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction= 20
  }

    scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type = "network-hdd"
      size = 10 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
    nat = true
}

  metadata = {
    user-data = file("./cloud-init.yml")
  }


}

resource "yandex_compute_instance" "web-a" {

  name ="web-a"
  hostname ="web-a"
    zone = "ru-central1-a" 
    platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

    scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type = "network-hdd"
      size = 10 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private1.id}"
    ip_address = "192.168.10.10"
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
  }

  metadata = {
    user-data = file("./cloud-init.yml")
  }
}

resource "yandex_compute_instance" "web-b" {

    name = "web-b"
    hostname = "web-b"
    zone = "ru-central1-b" 
    platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

    scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type = "network-hdd"
      size = 10 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private2.id}"
    ip_address = "192.168.20.10"
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
  }

  metadata = {
    user-data = file("./cloud-init.yml")
  }
}

resource "yandex_alb_target_group" "tg-1" {
  name = "tg-1"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private1.id}"
    ip_address = "${yandex_compute_instance.web-a.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private2.id}"
    ip_address = "${yandex_compute_instance.web-b.network_interface.0.ip_address}"
  }
}

resource "yandex_alb_backend_group" "backend-group" {
  name = "backend-group"

  http_backend {
    name = "bd-1"
    weight = 1  
    port = 80
    target_group_ids = [yandex_alb_target_group.tg-1.id]
    load_balancing_config {
      panic_threshold = 90
    }    
    healthcheck {
      timeout = "10s"
      interval = "2s"
      healthy_threshold = 10
      unhealthy_threshold = 15 
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "router" {
  name = "router"
}

resource "yandex_alb_virtual_host" "router-host" {
  name = "router-host"
  http_router_id = yandex_alb_http_router.router.id
  route {
    name = "route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend-group.id
        timeout = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "alb-1" {
  name = "alb-1"
  network_id  = "${yandex_vpc_network.network-1.id}"
  security_group_ids = [yandex_vpc_security_group.load-balancer-sg.id, yandex_vpc_security_group.private-sg.id] 
  
  allocation_policy {
    location {
      zone_id = "ru-central1-a"
      subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    }
  }

  
  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.router.id
      }
    }
  }
}

resource "yandex_compute_instance" "zabbix" {

  name = "zabbix"
  hostname ="zabbix"
  zone = "ru-central1-a" 

  platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction= 20
  }

    scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type = "network-hdd"
      size = 16
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    ip_address = "192.168.50.10"    
    nat = true
    security_group_ids = ["${yandex_vpc_security_group.private-sg.id}"]
  }

  metadata = {
    user-data = file("./cloud-init.yml")
  }
}

resource "yandex_compute_instance" "elastic" {

  name = "elastic"
  hostname = "elastic"
  zone = "ru-central1-a" 

  platform_id = "standard-v3"

  resources {
    cores = 4
    memory = 8
    core_fraction= 20
  }

    scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type = "network-hdd"
      size = 16
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private3.id}"
    security_group_ids = [yandex_vpc_security_group.private-sg.id, yandex_vpc_security_group.elasticsearch-sg.id]
    ip_address = "192.168.30.10"
  }
    metadata = {
      user-data = file("./cloud-init.yml")
  }
}  

resource "yandex_compute_instance" "kibana" {

  name = "kibana"
  hostname = "kibana"
  zone = "ru-central1-a" 

  platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction= 20
  }

    scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type = "network-hdd"
      size = 16 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    ip_address = "192.168.50.20"  
    nat = true
    security_group_ids = [yandex_vpc_security_group.private-sg.id, yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    user-data = file("./cloud-init.yml")
  }
}
