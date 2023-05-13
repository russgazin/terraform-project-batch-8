variable "sg_name" {}
variable "sg_tag" {}
variable "vpc_id" {}

variable "sg_rules" {
    type = map(any)
}