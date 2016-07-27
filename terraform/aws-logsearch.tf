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

  # inbound connections to haproxy
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }

  # inbound connections for diagnostics
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.source_access_block1}", "${var.source_access_block2}", "${var.source_access_block3}", "${var.source_access_block4}"]
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
    from_port   = 80
    to_port     = 80
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
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  tags {
  component = "logsearch"
  }
}

# Create a CNAME record
resource "aws_route53_record" "logsearch" {
   zone_id = "${var.ci_dns_zone_id}"
   name = "${var.logsearch_hostname}"
   type = "CNAME"
   ttl = "300"
   records = ["${aws_elb.logsearch.dns_name}"]
}
