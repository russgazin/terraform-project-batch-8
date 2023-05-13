variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/24"
}

variable "vpc_tag" {
  type    = string
  default = "project_vpc"
}

variable "create_and_attach_igw" {
  type    = bool
  default = true
}
