#VPC Level
resource "aws_vpc" "this" {
  cidr_block           = local.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

#Subnets
resource "aws_subnet" "public" {
  count = 1
  vpc_id                          = aws_vpc.this.id
  cidr_block                      = element(concat(local.public_subnets, [""]), count.index)
  availability_zone               = element(local.azs, count.index)
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = null
  tags = {
    "Name" = format(
      "${local.vpc_name}-public-%s",
      element(local.azs, count.index),
    )
  }
}

#Public routes to internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_internet_gateway_ipv6" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}