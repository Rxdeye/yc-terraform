# variables

variable "yandex_token" {
    type = string
    description = "Yandex cloud token"
    default = "YC_TOKEN"
  }

variable "folder_id" {
  type = string
  description = "folder_id"
  default = "FOLDER_ID"
}

variable "cloud_id" {
  type = string
  description = "cloud_id"
  default = "CLOUD_ID"
}
