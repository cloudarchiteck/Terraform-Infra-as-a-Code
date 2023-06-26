resource "aws_vpc" "main" {
    cidr_block       = var.cidr_block
    instance_tenancy = var.instance_tenancy
    enable_dns_support = var.dns_support
    enable_dns_hostnames = var.dns_hostnames
    tags = var.tags
}

# using for each loop to create subnet im multiple availability zones.

resource "aws_subnet" "public" {
  for_each = var.public_subnet
  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    name = each.value.name
  }
  
}
# imagine you have to create security group postgress RDS . Default port for postgress is 5432
resource "aws_security_group" "allow_postgress" {
  name        = "allow_postgress"
  description = "Allow postgress inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = var.postgress_port
    to_port          = var.postgress_port
    protocol         = "tcp"
    cidr_blocks      = var.cidr_list
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      name = "Saru-RDS-SG"

    }
  )
}

# this will be created inside default VPC
# AMI ID are different in each regions. If we have create multiple instances in multiple regions need to hard code with specifi AMI ID.
# if you copy down thrice - it will create 3 instances . Note: name should be changed. or we can use DRY. we can use count and count index concepts.

resource "aws_instance" "instances" {
  count          = length(var.instance_names)
  ami            = "ami-012b9156f755804f5"
  instance_type  = "t2.micro"
  tags = {
    Name = var.instance_names[count.index]
  }
}

resource "aws_instance" "ENV" {
  ami           = "ami-012b9156f755804f5"
  instance_type = var.ENV == "PROD" ? "t3.large" : "t2.micro"

  tags = {
    Name = "ENV"
    default = "true"
    type = "string"
  }
}
