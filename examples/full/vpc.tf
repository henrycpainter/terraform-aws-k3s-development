#VPC Level

locals {
  vpc_name       = "myVpc"
  cidr           = "10.1.0.0/16"
  public_subnets = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

#Subnets

data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_subnet" "public" {
  count                           = 1
  vpc_id                          = aws_vpc.this.id
  cidr_block                      = element(concat(local.public_subnets, [""]), count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = null
  tags = {
    "Name" = format(
      "${local.vpc_name}-public-%s",
      element(data.aws_availability_zones.available.names, count.index),
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
  gateway_id             = aws_internet_gateway.this.id
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_internet_gateway_ipv6" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = 1
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}