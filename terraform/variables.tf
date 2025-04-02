variable "zone_public" {
  description = "Зона для публичных ресурсов (Bastion, ALB)"
  type        = string
  default     = "ru-central1-d"
}

variable "zone_private1" {
  description = "Зона для первого приватного сегмента (Web-сервер 1)"
  type        = string
  default     = "ru-central1-d"
}

variable "zone_private2" {
  description = "Зона для второго приватного сегмента (Web-сервер 2)"
  type        = string
  default     = "ru-central1-b"
}

variable "image_id" {
  description = "ID образа для инстансов"
  type        = string
  default     = "fd85hkli5dp6as39ali4"
}
