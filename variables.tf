variable "access" {
  type = map(any)
  default = {
    token     = "<INSERT TOKEN OF YANDEX ACCOUNT>"
    cloud_id  = "<INSERT CLOUD ID>"
    folder_id = "<INSERT FOLDER ID>"
    zone      = "<INSERT CLOUD ZONE>"
  }
}

variable "data" {
  type = map(any)
  default = {
    count = 1
    account = "<INSERT ACCOUNT NAME>"
  }
}