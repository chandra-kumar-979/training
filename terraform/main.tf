module "s3bucket" {
  source = "./s3"
  bucket_name = var.bucket_name
  region      = var.region
  environment   = var.environment
}



module "subnet" {
  depends_on = [ module.vpc ]
  source = "./subnet"
  vpc_id = module.vpc.vpc_id
  cidr_block = var.subnet_cidr_block

}

module "vpc" {
  source = "./vpc"
  cidr_block = var.cidr_block

}

module "ec2" {
  source = "./ec2"
  subnet_id = module.subnet.aws_subnet
  ami_id = data.aws_ami.ubuntu.id
}