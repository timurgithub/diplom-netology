terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.90"
    }
  }
}

provider "yandex" {
  service_account_key_file = "../key.json"
  cloud_id                 = "b1gqql31log1hqeib9o3"
  folder_id                = "b1g898ireef9ia8ivgq4"
}
