resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = { for idx, az in var.availability_zones : az => {
    cidr = var.public_subnet_cidrs[idx]
  } }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = { for idx, az in var.availability_zones : az => {
    cidr = var.private_subnet_cidrs[idx]
  } }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = {
    Name = "${var.project_name}-private-${each.key}"
    Tier = "private"
  }
}

# ------------------------------------------------------------------------------
# NAT Gateway trade-off (controlled by var.single_nat_gateway):
#   true  -> 1 shared NAT Gateway (in the first AZ) used by ALL private subnets.
#            Cheaper (~1x NAT Gateway + EIP cost), but if that AZ has an outage,
#            every private subnet loses outbound internet access at once
#            (single point of failure).
#   false -> 1 NAT Gateway per AZ, each private subnet routes through the NAT
#            Gateway in its own AZ. Highly available, but costs roughly 3x as
#            much (one NAT Gateway + one Elastic IP per AZ).
# For learning/dev environments, `true` (default) is recommended to save cost.
# ------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  for_each = var.single_nat_gateway ? toset([var.availability_zones[0]]) : toset(var.availability_zones)

  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${each.key}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  for_each = var.single_nat_gateway ? toset([var.availability_zones[0]]) : toset(var.availability_zones)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.project_name}-nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.main]
}
