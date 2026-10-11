resource "aws_vpc" "petclinic" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "petclinic-vpc"
    Environment = "dev"
    Project     = "PetClinic"
  }
}

resource "aws_internet_gateway" "petclinic" {
  vpc_id = aws_vpc.petclinic.id

  tags = {
    Name        = "petclinic-igw"
    Environment = "dev"
    Project     = "PetClinic"
  }
}

resource "aws_route_table" "petclinic_public" {
  vpc_id = aws_vpc.petclinic.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.petclinic.id
  }

  tags = {
    Name        = "petclinic-public-rt"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
resource "aws_subnet" "petclinic_az1" {
  vpc_id                  = aws_vpc.petclinic.id
  cidr_block              = "172.31.16.0/20"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "petclinic-subnet-eu-north-1a"
    Environment = "dev"
    Project     = "PetClinic"
  }
}

resource "aws_subnet" "petclinic_az2" {
  vpc_id                  = aws_vpc.petclinic.id
  cidr_block              = "172.31.32.0/20"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "petclinic-subnet-eu-north-1b"
    Environment = "dev"
    Project     = "PetClinic"
  }
}

resource "aws_subnet" "petclinic_az3" {
  vpc_id                  = aws_vpc.petclinic.id
  cidr_block              = "172.31.0.0/20"
  availability_zone       = "eu-north-1c"
  map_public_ip_on_launch = true

  tags = {
    Name        = "petclinic-subnet-eu-north-1c"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
