variable "cidr_block" {
  description = "master cidr block"
  type        = string
}

variable "public_subnet_prefix" {
  description = "public subnet prefix's"
  type        = list(any)
}

variable "private_subnet_prefix" {
  description = "public subnet prefix's"
  type        = list(any)
}

variable "security_group_prefix" {
  description = "security group prefix's"
  type        = list(any)
}

variable "availability_zones" {
  description = "availability zones"
  type        = list(any)
}

variable "primary_db_username" {
  description = "database username"
  type        = string
}

variable "primary_db_password" {
  description = "database password"
  type        = string
}
