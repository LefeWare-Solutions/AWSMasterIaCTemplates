variable "vpc_name" {
  type        = string
  description = ""
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "cidr_block"{
  type    =  string
  default = "10.0.0.0/16"
}