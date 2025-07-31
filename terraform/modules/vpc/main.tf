resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_cidr
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

# Public subnets
resource "aws_subnet" "public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.tags,
    var.public_subnet_tags,
    {
      Name = "${var.name}-public-${local.availability_zones[count.index]}"
      Type = "Public"
      Tier = "Public"
    }
  )
}

# Private subnets
resource "aws_subnet" "private" {
  count = local.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(
    var.tags,
    var.private_subnet_tags,
    {
      Name = "${var.name}-private-${local.availability_zones[count.index]}"
      Type = "Private"
      Tier = "Private"
    }
  )
}

# App subnets
resource "aws_subnet" "app" {
  count = local.app_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.app_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(
    var.tags,
    var.app_subnet_tags,
    {
      Name = "${var.name}-app-${local.availability_zones[count.index]}"
      Type = "App"
      Tier = "App"
    }
  )
}

# Database subnets
resource "aws_subnet" "database" {
  count = local.database_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.database_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(
    var.tags,
    var.database_subnet_tags,
    {
      Name = "${var.name}-database-${local.availability_zones[count.index]}"
      Type = "Database"
      Tier = "Database"
    }
  )
}

# NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway && local.private_subnet_count > 0 && local.public_subnet_count > 0 ? (var.single_nat_gateway ? 1 : local.private_subnet_count) : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway && local.private_subnet_count > 0 && local.public_subnet_count > 0 ? (var.single_nat_gateway ? 1 : local.private_subnet_count) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-gw-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# Route tables
resource "aws_route_table" "public" {
  count = local.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
      Type = "Public"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  count = local.public_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = local.private_subnet_count > 0 ? (var.single_nat_gateway ? 1 : local.private_subnet_count) : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt${var.single_nat_gateway ? "" : "-${count.index}"}"
      Type = "Private"
    }
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway && local.private_subnet_count > 0 && local.public_subnet_count > 0 ? (var.single_nat_gateway ? 1 : local.private_subnet_count) : 0

  route_table_id         = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count = local.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table" "app" {
  count = local.app_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-app-rt"
      Type = "App"
    }
  )
}

resource "aws_route" "app_internet_gateway" {
  count = local.app_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.app[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "app" {
  count = local.app_subnet_count

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[0].id
}


resource "aws_route_table" "database" {
  count = local.database_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-database-rt"
      Type = "Database"
    }
  )
}

resource "aws_route_table_association" "database" {
  count = local.database_subnet_count

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}
