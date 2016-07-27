# Create a Logsearch security group
resource "aws_security_group" "logsearch-sg" {
  name        = "logsearch-sg"
  description = "logsearch security group"
  vpc_id      = "${aws_vpc.default.id}"
  tags {
  Name = "logsearch-sg"
  component = "logsearch"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound connections to Kibana
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }

}

# Create an ELB security group
resource "aws_security_group" "elb-ls-sg" {
  name        = "elb-ls-sg"
  description = "ELB security group"
  vpc_id      = "${aws_vpc.default.id}"
  tags {
  Name = "elb-ls-sg"
  component = "logsearch"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound http
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create a new load balancer
resource "aws_elb" "logsearch" {
  name = "logsearch-elb"
  subnets = ["${aws_subnet.ops_services.id}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]

  listener {
    instance_port = 5601
    instance_protocol = "http"
    lb_port = 5601
    lb_protocol = "http"
  }

  tags {
  component = "logsearch"
  }
}

# Create a CNAME record
resource "aws_route53_record" "logsearch" {
   zone_id = "${var.ci_dns_zone_id}"
   name = "${var.ci_hostname}"
   type = "CNAME"
   ttl = "300"
   records = ["${aws_elb.logsearch.dns_name}"]
}
