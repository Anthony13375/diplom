  resource "yandex_compute_snapshot_schedule" "backup" {
   name = "backup"

   schedule_policy {
     expression = "0 0 * * *"
   }

   snapshot_count = 7

   disk_ids = [
     "${yandex_compute_instance.bastion.boot_disk.0.disk_id}",
     "${yandex_compute_instance.web-a.boot_disk.0.disk_id}",
     "${yandex_compute_instance.web-b.boot_disk.0.disk_id}",
     "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}",
     "${yandex_compute_instance.elastic.boot_disk.0.disk_id}",
     "${yandex_compute_instance.kibana.boot_disk.0.disk_id}",
   ]
 }
