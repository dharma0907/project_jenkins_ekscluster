//availability zones

data "aws_availability_zones" "avaialble" {
  
}

// Now crating a vpc

resource "aws_vpc" "eksvpc" {

    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
    Name = "VPCforEksProject"
  }
  
}
// we need to create internet gateway for intent connection to VPC

resource "aws_internet_gateway" "internetGateway" {

    vpc_id = aws_vpc.eksvpc.id

    tags = {
      Name = "igw"
    }
  
}

//Creating 2 public subnets and 2 private subnets
resource "aws_subnet" "ps1" {

    vpc_id = aws_vpc.eksvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = var.availability_zone[0]
    map_public_ip_on_launch = true

     tags = {
        Name = "publicsubnet1"
     } 
}

resource "aws_subnet" "ps2" {

    vpc_id = aws_vpc.eksvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.availability_zone[1]
    map_public_ip_on_launch = true
    
    tags = {

        Name = "publicsubnet2"
    }
}

//creating private subnets
resource "aws_subnet" "private_subnet1" {
  vpc_id = aws_vpc.eksvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zone[2]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "privatesubnet-useast-1c"
  }
  
}


resource "aws_subnet" "private_subnet2" {
  vpc_id = aws_vpc.eksvpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = var.availability_zone[3]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "privatesubnet-useast-1d"
  }

}
//***********************************************************
//Nat gateways:

# Configure Elastic IP as static IP for your NAT gateway
resource "aws_eip" "nat" {
  # EIP may require IGW to exist prior to association. 
  # Use depends_on to set an explicit dependency on the IGW.
  depends_on = [aws_internet_gateway.internetGateway]
}

resource "aws_nat_gateway" "natGateway" {
  allocation_id = aws_eip.nat.id

  # The Subnet ID of the subnet in which to place the gateway.
  subnet_id = aws_subnet.ps1.id
  
  tags = {
    Name = "ngw"
  }
}
//********************************************************
# public example
resource "aws_route_table" "publicroute_ps1" {
  vpc_id = aws_vpc.eksvpc.id

  route {
    # redirect 0.0.0.0/0 (all traffic) to igw
    cidr_block = "0.0.0.0/0"
    # associate to previously created igw, attaching internetgateway for routetable
    gateway_id = aws_internet_gateway.internetGateway.id
  }

  tags = {
    Name = "publicroute_ps1"
  }
}
resource "aws_route_table" "publicroute_ps2" {
  vpc_id = aws_vpc.eksvpc.id

  route {
    # redirect 0.0.0.0/0 (all traffic) to igw
    cidr_block = "0.0.0.0/0"
    # associate to previously created igw, attaching internetgateway for routetable
    gateway_id = aws_internet_gateway.internetGateway.id
  }

  tags = {
    Name = "public-ps2"
  }
}
# private example
resource "aws_route_table" "privateroute_privatesubnet1" {
  # The VPC ID.
  vpc_id = aws_vpc.eksvpc.id

  # redirect 0.0.0.0/0 (all traffic) to NAT
  route {
    cidr_block = "0.0.0.0/0"
    # associate to previously created nat gw
    nat_gateway_id = aws_nat_gateway.natGateway.id
  }

  # A map of tags to assign to the resource.
  tags = {
    Name = "privateroute_privatesubnet1"
  }
}
resource "aws_route_table" "privateroute_privatesubnet2" {
  # The VPC ID.
  vpc_id = aws_vpc.eksvpc.id

  # redirect 0.0.0.0/0 (all traffic) to NAT
  route {
    cidr_block = "0.0.0.0/0"
    # associate to previously created nat gw
    nat_gateway_id = aws_nat_gateway.natGateway.id
  }

  # A map of tags to assign to the resource.
  tags = {
    Name = "privateroute_privatesubnet2"
  }
}
//**************NOW WE HAVE TO ASSOCIATE ROUTE TABLE*****************************

resource "aws_route_table_association" "subnet_public1" {
  subnet_id = aws_subnet.ps1.id
  route_table_id = aws_route_table.publicroute_ps1.id
}
resource "aws_route_table_association" "subnet_public2" {
  subnet_id = aws_subnet.ps2.id
  route_table_id = aws_route_table.publicroute_ps2.id
}

resource "aws_route_table_association" "subnet_private1" {
  subnet_id = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.privateroute_privatesubnet1.id
}
resource "aws_route_table_association" "subnet_private2" {
  subnet_id = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.privateroute_privatesubnet2.id
}
