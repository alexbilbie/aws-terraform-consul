provider "aws" {
  access_key = "XXX"
  secret_key = "XXX"
  region     = "eu-west-1"
}

data "aws_ami" "ubuntu_1604" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Security groups
resource "aws_security_group" "consul" {
  name_prefix = "consul"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "consul"
  }
}

resource "aws_security_group_rule" "consul_dns_udp" {
  type                     = "ingress"
  from_port                = 8600
  to_port                  = 8600
  protocol                 = "UDP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_dns_tcp" {
  type                     = "ingress"
  from_port                = 8600
  to_port                  = 8600
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_rpc_udp" {
  type                     = "ingress"
  from_port                = 8300
  to_port                  = 8300
  protocol                 = "UDP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_rpc_tcp" {
  type                     = "ingress"
  from_port                = 8300
  to_port                  = 8300
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_consul_agent_http" {
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_consul_agent_cli" {
  type                     = "ingress"
  from_port                = 8400
  to_port                  = 8400
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_serf_lan_udp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "UDP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_serf_lan_tcp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_serf_wan_udp" {
  type                     = "ingress"
  from_port                = 8302
  to_port                  = 8302
  protocol                 = "UDP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_serf_wan_tcp" {
  type                     = "ingress"
  from_port                = 8302
  to_port                  = 8302
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.consul.id}"
  security_group_id        = "${aws_security_group.consul.id}"
}

# Elastic Network Interfaces

resource "aws_network_interface" "consul_eni_az_a" {
  subnet_id       = "${aws_subnet.private_a.id}"
  security_groups = ["${aws_security_group.consul.id}"]

  tags = {
    Name = "eu-west-1a"
  }

  tags = {
    Name = "consul-master"
  }
}

resource "aws_network_interface" "consul_eni_az_b" {
  subnet_id       = "${aws_subnet.private_b.id}"
  security_groups = ["${aws_security_group.consul.id}"]

  tags = {
    Name = "eu-west-1b"
  }

  tags = {
    Name = "consul-master"
  }
}

resource "aws_network_interface" "consul_eni_az_c" {
  subnet_id       = "${aws_subnet.private_c.id}"
  security_groups = ["${aws_security_group.consul.id}"]

  tags = {
    Name = "eu-west-1c"
  }

  tags = {
    Name = "consul-master"
  }
}

# Launch configuration

resource "aws_launch_configuration" "consul_master" {
  name_prefix   = "consul_master_"
  image_id      = "${data.aws_ami.ubuntu_1604.id}"
  instance_type = "t2.nano"
  user_data     = "${file("user-data.sh")}"

  lifecycle {
    create_before_destroy = true
  }
}
