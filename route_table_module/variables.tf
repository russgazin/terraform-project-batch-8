variable "vpc_id" {}

variable "gateway_id" {
  default = null
}

variable "nat_gateway_id" {
  default = null
}

variable "subnet_ids" {
  type = list(string)
}
