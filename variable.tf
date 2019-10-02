variable "region" {
    type= "string"
  default = "ap-south-1"
}

variable "access_key" {
    type = "string"
  default = ""
}

variable "secret_key" {
    type = "string"
  default = ""
}

variable "vpc_name" {
    type = "map"
  default = {
          Name = "VPC"
          cidr_block = "192.168.0.0/16"
      }
}

variable "public_subnet" {
    type = "map"
  default = {
          Name = "Public-Subnet"
          cidr_block = "192.168.1.0/24"
          availability_zone = "ap-south-1a"
      }
}
variable "private_subnet" {
    type = "map"
  default = {
          Name = "Private-Subnet"
          cidr_block = "192.168.2.0/24"
          availability_zone = "ap-south-1b"
      }
}

variable "aws_internet_gateway" {
  type = "map"
  default = {
    Name = "IGW"
  }
}

variable "aws_route_table" {
  type = "string"
  default = "IGW-RT"
}

variable "aws_route_table_association" {
  type = "string"
  default = "publicsubnetRT"
}

variable "aws_security_group" {
  type = "string"
  default = "SG"
}

variable "instance_count" {
  default = "2"
}

variable "aws_instance" {
    type = "map"
    default = {
        ami = "ami-04125d804acca5692"
        instance_type = "t2.micro"
      
        ami = "ami-04125d804acca5692"
        instance_type = "t2.micro"
    }
}

variable "file" {
  default = "main.sh"
}

variable "aws_elb" {
  type = "map"
  default = {
    name = "load-balancer"
  }
}

variable "aws_launch_configuration" {
  type= "map"
  default = {
    name = "Launch-Configuration"
  }
}

variable "aws_autoscaling_group" {
  type = "map"
  default = {
    name = "Auto-Scaling-Group"
  }
}


