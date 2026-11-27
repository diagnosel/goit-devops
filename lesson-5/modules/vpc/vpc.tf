resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.vpc_name }
}

resource "aws_subnet" "public" {
  for_each = zipmap(var.availability_zones, var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.vpc_name}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = zipmap(var.availability_zones, var.private_subnets)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.vpc_name}-private-${each.key}" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.vpc_name}-nat-ip" }
}

resource "aws_nat_gateway" "this" {
  availability_mode = "zonal"
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.public[var.availability_zones[0]].id
  tags              = { Name = "${var.vpc_name}-nat" }

  depends_on = [aws_internet_gateway.this]
}
