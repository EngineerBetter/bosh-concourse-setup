# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

    tags {
    Name = "bosh-default"
    component = "bosh-director"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
  Name = "bosh-default"
  component = "bosh-director"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1a"
  tags {
  Name = "bosh-default"
  component = "bosh-director"
  }
}

# Create an EIP for our Director
resource "aws_eip" "boshdirector" {
    vpc = true
}

# A security group
resource "aws_security_group" "boshdefault" {
  name        = "boshdefault"
  description = "Default BOSH security group"
  vpc_id      = "${aws_vpc.default.id}"
  tags {
  Name = "bosh-default"
  component = "bosh-director"
  }

	# inbound access rules
  ingress {
    from_port   = 6868
    to_port     = 6868
    protocol    = "tcp"
		cidr_blocks = ["${var.source_access_ip}"]
  }

	ingress {
		from_port   = 25555
		to_port     = 25555
		protocol    = "tcp"
		cidr_blocks = ["${var.source_access_ip}"]
	}

	ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["${var.source_access_ip}"]
	}

	ingress {
		from_port   = 0
		to_port     = 65535
		protocol    = "tcp"
		self        = true
	}

	ingress {
		from_port   = 0
		to_port     = 65535
		protocol    = "udp"
		self        = true
	}

	# outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
