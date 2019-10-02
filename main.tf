
provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_vpc" "VPC" {
  cidr_block = "${lookup(var.vpc_name,"cidr_block")}"
  tags = {
    Name = "${lookup(var.vpc_name,"Name")}"
  }
}

resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.VPC.id}"
    availability_zone = "${lookup(var.public_subnet, "availability_zone")}"
    cidr_block = "${lookup(var.public_subnet,"cidr_block")}"
    tags = {
    Name = "${lookup(var.public_subnet,"Name")}"
  }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = "${aws_vpc.VPC.id}"
    availability_zone = "${lookup(var.private_subnet, "availability_zone")}"
    cidr_block = "${lookup(var.private_subnet,"cidr_block")}"
    tags = {
    Name = "${lookup(var.private_subnet,"Name")}"
  }
}


resource "aws_internet_gateway" "IGW" {
    vpc_id = "${aws_vpc.VPC.id}" 

    tags = {
    Name = "IGW"
    }
}

resource "aws_route_table" "IGW-RT" {
    vpc_id = "${aws_vpc.VPC.id}" 
    
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
    }

    tags = {
    Name = "Public_route"
    }
}

resource "aws_route_table_association" "publicsubnetRT" {
    subnet_id = "${aws_subnet.public_subnet.id}"
    route_table_id = "${aws_route_table.IGW-RT.id}"
}

resource "aws_security_group" "SG" {
    name = "${var.aws_security_group}"
    vpc_id = "${aws_vpc.VPC.id}"
    description = "Allow HTTP, HTTPS, SSH"
    
    ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_eip" "Elastic_IP" {
  vpc = true
  }

resource "aws_nat_gateway" "NAT-GW" {
  allocation_id = "${aws_eip.Elastic_IP.id}"
  subnet_id = "${aws_subnet.public_subnet.id}"

  tags = {
    Name = "NAT-GW"
  }
}

resource "aws_route_table" "NAT-RT" {
    vpc_id = "${aws_vpc.VPC.id}" 
    
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.NAT-GW.id}"
    }

    tags = {
    Name = "Private_route"
    }
}

resource "aws_route_table_association" "privatesubnetRT" {
    subnet_id = "${aws_subnet.private_subnet.id}"
    route_table_id = "${aws_route_table.NAT-RT.id}"
}

resource "aws_instance" "server" {
    count = "${length(var.aws_instance)}"
    ami                    = "${lookup(var.aws_instance,"ami")}"
    instance_type          = "${lookup(var.aws_instance,"instance_type")}"
    subnet_id              = "${aws_subnet.public_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.SG.id}"]
    associate_public_ip_address = "1"
    key_name = "Meghana"
    user_data = "${file(var.file)}"

    tags = {
       Name = "server"
    }
}

resource "aws_elb" "load-balancer" {
  name = "${lookup(var.aws_elb,"name")}"
  internal = false
  security_groups = ["${aws_security_group.SG.id}"]
  subnets = [
    "${aws_subnet.public_subnet.id}",
    "${aws_subnet.private_subnet.id}"
  ]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  } 

  instances             = "${aws_instance.server.*.id}"
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 300

  tags =  {
    Name = "load-balancer"
  }
}

resource "aws_launch_configuration" "Launch-Configuration" {
  name   = "${lookup(var.aws_launch_configuration,"name")}"
  image_id      ="${lookup(var.aws_instance,"ami")}"
  instance_type = "${lookup(var.aws_instance,"instance_type")}"
  security_groups = ["${aws_security_group.SG.id}"]
  associate_public_ip_address = "1"
  key_name = "Meghana"
  user_data = "${file(var.file)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "Auto-Scaling-Group" {
  name                 = "${lookup(var.aws_autoscaling_group,"name")}"
  launch_configuration = "${aws_launch_configuration.Launch-Configuration.name}"
  load_balancers = ["${aws_elb.load-balancer.id}"]
  vpc_zone_identifier = ["${aws_subnet.public_subnet.id}"]
  min_size             = 2
  max_size             = 3

    tags = [
      {
      key = "name"
      value = "${lookup(var.aws_autoscaling_group,"name")}"
      propagate_at_launch = true
    }
  ]
    
    lifecycle {
    create_before_destroy = true
  }
}



