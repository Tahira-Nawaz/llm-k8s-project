data "aws_vpc" "existing" {
  id = var.vpc_id
}

resource "aws_subnet" "public" {
  # count = length(var.public_subnet_cidrs)

  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}