resource "aws_route_table" "nat_route_table" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
}

resource "aws_route_table" "product" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group" "nat_security_group" {
  name        = "nat_security_group"
  description = "NAT Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    cidr_blocks = ["${var.vpc_cidr}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-nat-security-group"))}"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnets.*.id, 0)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-nat"))}"
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = "${var.tags}"
}

resource "aws_route" "toggle_internet" {
  count = "${var.internetless ? 0 : length(var.availability_zones)}"

  route_table_id         = "${element(aws_route_table.product.*.id, count.index)}"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
  destination_cidr_block = "0.0.0.0/0"
}
