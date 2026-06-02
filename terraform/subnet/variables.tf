variable "cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string

}

variable "vpc_id" {
  description = "The ID of the VPC where the subnet will be created"
  type        = string
}