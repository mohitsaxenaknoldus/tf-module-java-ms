variable "main_vpc_cidr" {
  type    = string
  default = "10.98.49.0/24"
}

variable "public_subnets_cidr" {
  type    = list(string)
  default = ["10.98.49.0/28"]
}

variable "public_subnets_a_cidr" {
  type    = list(string)
  default = ["10.98.49.16/28"]
}

variable "private_subnets_cidr" {
  type    = list(string)
  default = ["10.98.49.128/28"]
}

variable "private_subnets_a_cidr" {
  type    = list(string)
  default = ["10.98.49.32/28"]
}

variable "env" {
  type    = string
  default = "dev"
}