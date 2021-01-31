## These  come from the ansible side.

variable "target_region" {
  description = "AWS Region to use whilst provisioning this infrastructure"
  type        = string
  default     = "eu-west-1"
}

variable "target_infra" {
  description = "AWS Target Infrastructure (prod or nonprod)"
  type        = string
  default     = "nonprod"
}

variable "app_parent" {
  description = "Application parent/category"
  type        = "test"
}

variable "app_name" {
  description = "Application Name"
  type        = string
  default     = "wordpress"
}
