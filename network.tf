resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "test-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "subnet-private1" {
  name           = "subnet-private1"
  description    = "subnet for web-a"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-private2" {
  name           = "subnet-private2"
  description    = "subnet for web-b"
  zone           = "ru-central1-b" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_vpc_subnet" "subnet-private3" {
  name           = "subnet-private3"
  description    = "subnet for elasticsearch"
  zone           = "ru-central1-a" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.30.0/24"]
}

resource "yandex_vpc_subnet" "subnet-public1" {
  name           = "subnet-public1"
  description    = "subnet for services"
  zone           = "ru-central1-a" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["192.168.50.0/24"]
}
