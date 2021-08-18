###########PROVIDER Section############
provider "aws" {
  region = "us-east-1"
}

########## DATA Section ##############

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

#  filter {
#    name   = "owner-alias"
#    values = ["amazon"]
#  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*x86_64-ebs"]
  }
}

########### Modules ###################
module "vpc1" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "vpc-1"
  cidr = "172.3.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["172.3.0.0/24", "172.3.1.0/24"]
  enable_dns_hostnames = true 
  enable_dns_support   = true
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "vpc2" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-2"
  cidr = "172.9.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["172.9.0.0/24", "172.9.1.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true  
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}


############## Resources ##################

resource "aws_security_group" "sg-vpc-1" {
  name        = "sgvpc1"
  description = "Allow Web traffic"
  vpc_id      = module.vpc1.vpc_id
  dynamic "ingress" {
    for_each = var.ingressrules
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "sgvpc1"
  }
}


resource "aws_security_group" "sg-vpc-2" {
  name        = "sgvpc2"
  description = "Allow Web traffic"
  vpc_id      = module.vpc2.vpc_id
  dynamic "ingress" {
    for_each = var.ingressrules
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "sgvpc2"
  }
}


resource "aws_instance" "server1" {
  count                  = var.numofec2instance
  subnet_id              = sort(module.vpc1.public_subnets)[count.index]
  ami                    = data.aws_ami.amazon-linux-2.id
  key_name               = var.keyname
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg-vpc-1.id]
  tags = {
    Name = "vpc1-ec2-${count.index + 1}"
  }
  connection{
	type = "ssh"
	user = "ec2-user"
	private_key = "${file("MyKeyPair.pem")}"
        host = self.public_ip
  }
  provisioner "remote-exec"{
	inline = ["sudo yum install docker -y", "sudo systemctl start docker", "sudo docker run -itd -p 80:80 benpiper/r53-ec2-web"]
  }
}

resource "aws_instance" "server2" {
  count                  = var.numofec2instance
  subnet_id              = sort(module.vpc2.public_subnets)[count.index]
  ami                    = data.aws_ami.amazon-linux-2.id
  key_name               = var.keyname
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg-vpc-2.id]
  tags = {
    Name = "vpc2-ec2-${count.index + 1}"
  }
  connection{
        type = "ssh"
        user = "ec2-user"
        private_key = "${file("MyKeyPair.pem")}"
        host = self.public_ip
  }
  provisioner "remote-exec"{
        inline = ["sudo yum install docker -y", "sudo systemctl start docker", "sudo docker run -itd -p 80:80 benpiper/r53-ec2-web"]
  }
}
