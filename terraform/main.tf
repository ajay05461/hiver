###########PROVIDER Section############
provider "aws" {
  region = "us-east-1"
}

########## DATA Section ##############

data "aws_subnet_ids" "default_subnets" {
  vpc_id = aws_default_vpc.default.id
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

########### RESOURCE Section ##########
resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "prod-web-servers-sg" {
  name        = "prod-web-servers-sg"
  description = "Allow Web traffic"
  vpc_id      = aws_default_vpc.default.id
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
    Name = "prod-web-servers-sg"
  }
}

resource "aws_instance" "nginxserver" {
  count                  = var.numofec2instance
  subnet_id              = sort(data.aws_subnet_ids.default_subnets.ids)[count.index]
  ami                    = data.aws_ami.amazon-linux-2.id
  key_name               = var.keyname
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.prod-web-servers-sg.id]
  user_data              = fileexists("script.sh") ? file("script.sh") : null
  tags = {
    Name = "prod-web-server-${count.index + 1}"
  }
}

resource "aws_lb" "nlb" {
  name               = "network-load-balancer"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.default_subnets.ids

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "tcp-nlb-tg" {
  name     = "tcp-nlb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_default_vpc.default.id
}


resource "aws_lb_target_group_attachment" "tcp-nlb-tg-attachment" {
  count            = var.numofec2instance
  target_group_arn = aws_lb_target_group.tcp-nlb-tg.arn
  target_id        = aws_instance.nginxserver[count.index].id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp-nlb-tg.arn
  }
}
